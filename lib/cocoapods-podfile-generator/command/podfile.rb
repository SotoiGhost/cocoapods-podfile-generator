require 'cocoapods-podfile-generator/podfilegeneratorinformative'
require 'cocoapods-podfile-generator/version.rb'

module Pod
  class Command
    # This is an example of a cocoapods plugin adding a top-level subcommand
    # to the 'pod' command.
    #
    # You can also create subcommands of existing or new commands. Say you
    # wanted to add a subcommand to `list` to show newly deprecated pods,
    # (e.g. `pod list deprecated`), there are a few things that would need
    # to change.
    #
    # - move this file to `lib/pod/command/list/deprecated.rb` and update
    #   the class to exist in the the Pod::Command::List namespace
    # - change this class to extend from `List` instead of `Command`. This
    #   tells the plugin system that it is a subcommand of `list`.
    # - edit `lib/cocoapods_plugins.rb` to require this file
    #
    # @todo Create a PR to add your plugin to CocoaPods/cocoapods.org
    #       in the `plugins.json` file, once your plugin is released.
    #
    class Podfile < Command
      require 'pathname'

      self.summary = CocoapodsPodfileGenerator::SUMMARY
      self.description = CocoapodsPodfileGenerator::DESCRIPTION

      self.arguments = [
        CLAide::Argument.new(CocoapodsPodfileGenerator::POD_ARGUMENT_NAME, required: false, repeatable: true)
      ]

      def self.options
        [
          ["--#{CocoapodsPodfileGenerator::REGEX_FLAG_NAME}", "Interpret the pod names as a regular expression"],
          ["--#{CocoapodsPodfileGenerator::INCLUDE_DEPENDENCIES_FLAG_NAME}", "Include each pod's dependencies name in the Podfile."],
          ["--#{CocoapodsPodfileGenerator::INCLUDE_DEFAULT_SUBSPECS_FLAG_NAME}", "Include the `default_subspecs` values in the Podfile if any."],
          ["--#{CocoapodsPodfileGenerator::INCLUDE_ALL_SUBSPECS_FLAG_NAME}", "Include all the subspecs in the Podfile if any."],
          ["--#{CocoapodsPodfileGenerator::INCLUDE_ANALYZE}", "Let cocoapods to resolve the dependencies needed for the pods provided and include them in the Podfile."],
          ["--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}", "A text file containing the pods to add to the Podfile. Each row within the file should have the format: <POD_NAME>:<POD_VERSION>. Example: --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=path/to/file.txt"],
          ["--#{CocoapodsPodfileGenerator::PLATFORMS_OPTION_NAME}", "Platforms to consider. If not set, all platforms supported by the pods will be used. A target will be generated per platform. Example: --#{CocoapodsPodfileGenerator::PLATFORMS_OPTION_NAME}=ios,tvos"],
          ["--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}", "Path where the Podfile will be saved. If not set, the Podfile will be saved where the command is running. Example: --#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=path/to/save/Podfile_name"],
        ].concat(super)
      end

      def initialize(argv)
        # Let's get all the command line arguments.
        @pods = {}
        @pods_args = argv.arguments!
        @use_regex = argv.flag?(CocoapodsPodfileGenerator::REGEX_FLAG_NAME)
        @include_dependencies = argv.flag?(CocoapodsPodfileGenerator::INCLUDE_DEPENDENCIES_FLAG_NAME)
        @include_default_subspecs = argv.flag?(CocoapodsPodfileGenerator::INCLUDE_DEFAULT_SUBSPECS_FLAG_NAME)
        @include_all_subspecs = argv.flag?(CocoapodsPodfileGenerator::INCLUDE_ALL_SUBSPECS_FLAG_NAME)
        @include_analyze = argv.flag?(CocoapodsPodfileGenerator::INCLUDE_ANALYZE)
        @pods_textfile = argv.option(CocoapodsPodfileGenerator::FILE_OPTION_NAME)
        @platforms = argv.option(CocoapodsPodfileGenerator::PLATFORMS_OPTION_NAME, "").split(",")
        @podfile_output_path = argv.option(CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME, "#{Dir.pwd}/Podfile")
        super
      end

      def validate!
        help! "You must give a Pod argument or pass a path to a text file to parse the Pods." if @pods_args.empty? && @pods_textfile.nil?

        # Parse each argument passed if any
        begin
          @pods_args.each { |pod| @pods.merge!(parse_line(pod)) } if not @pods_args.empty?
        rescue PodfileGeneratorInformative => e
          help! "There was a problem parsing the argument #{e.message}."
        end
        
        # Parse each line of the text file if there's a file
        if @pods_textfile
          pods_textfile = Pathname.new(@pods_textfile)
          help! "The file was not found at #{@pods_textfile} to fetch the pods." if not pods_textfile.exist?

          begin
            pods_textfile.each_line { |line| @pods.merge!(parse_line(line)) }
          rescue PodfileGeneratorInformative => e
            help! "There was a problem parsing the line #{e.message} at file #{@pods_textfile}."
          end
        end

        # Validate that each Pod with its specified versions exist by using the `pod spec which` command.
        @pods.each do |pod_name, pod_version|
          # Arguments needed for the command.
          args = [pod_name]
          args += ["--#{CocoapodsPodfileGenerator::REGEX_FLAG_NAME}"] if @use_regex

          begin
            which_spec = Pod::Command::Spec::Which.new CLAide::ARGV.new(args + ["--version=#{pod_version}"])
            which_spec.run
          rescue Pod::Informative => e
            raise PodfileGeneratorInformative, "There was a problem trying to locate the pod #{pod_name} (#{pod_version})\n" +
              "Original error message: #{e.message}"
          end
        end

        super
      end

      def run
        # As we already validate the arguments provided, it's safe to get the podspecs.
        specs = @pods.keys.map { |pod_name| get_specification(pod_name.to_s, @pods[pod_name]) }
        resolve_platforms_if_needed(specs)
        
        if @include_dependencies || @include_analyze
          specs_by_platform = resolve_dependencies(specs)
        else
          specs_by_platform = get_specs_by_platform(specs)
        end

        generate_podfile_file(specs_by_platform, @podfile_output_path)
      end

      private

      # Parse a string line to a hash.
      def parse_line(line)
        line.strip!
        raise PodfileGeneratorInformative, line if not line =~ /^.+:.+$/
        pod_name, pod_version = line.split(":")
        Hash[pod_name.to_sym, pod_version]
      end

      # Gets the podspec for an specific version
      def get_specification(pod_name, pod_version)
        query = @use_regex ? pod_name : Regexp.escape(pod_name)
        set = config.sources_manager.search_by_name(query).first
        spec_path = set.specification_paths_for_version(Pod::Version.new(pod_version)).first
        spec = Pod::Specification.from_file(spec_path)
        
        # Remove the default subspecs value to consider all exisiting subspecs within a spec
        spec.default_subspecs = [] if @include_all_subspecs || spec.default_subspecs == :none
        spec
      end

      def resolve_platforms_if_needed(specs)
        # Get all the supported platforms without the OS version if no platforms are specified
        @platforms = specs
          .map { |spec| spec.available_platforms.map(&:name) }
          .flatten
          .uniq if @platforms.empty?
        @platforms.map! { |platform| Pod::Platform.new(platform) }
      end

      # Analyze and resolve all the specs needed for this spec.
      def resolve_dependencies(specs)
        specs_by_platform = get_specs_by_platform(specs)

        podfile = podfile(specs_by_platform)
        resolved_specs = Pod::Installer::Analyzer.new(config.sandbox, podfile).analyze.specs_by_target

        # After an analyze, we get every specs needed to make this Podfile work,
        # Let's filter the specs according to the user needs.
        @platforms.each do |platform|
          key = resolved_specs.keys.find { |key| key.name.end_with?(platform.name.to_s) }
          next if key.nil?

          if @include_analyze
            specs_by_platform[platform.name] = resolved_specs[key]
          else
            dependecies_names = specs_by_platform[platform.name].map { |spec| spec.dependencies(platform).map(&:name) }.flatten.uniq
            specs_by_platform[platform.name] += resolved_specs[key].select { |spec| dependecies_names.include?(spec.name) }

            # Let's remove any duplicated specs
            specs_by_platform[platform.name].uniq!(&:name)
          end
        end

        specs_by_platform
      end

      def get_specs_by_platform(specs)
        specs_by_platform = {}
        @platforms.each do |platform|
          specs_by_platform[platform.name] = specs.select { |spec| spec.supported_on_platform?(platform) }
          
          next if !@include_all_subspecs && !@include_default_subspecs

          # Include the subspecs of all the specs if any
          if @include_all_subspecs
            specs.each do |spec| 
              specs_by_platform[platform.name] += spec.recursive_subspecs.reject(&:non_library_specification?).select { |subspec| subspec.supported_on_platform?(platform) }
            end
          elsif @include_default_subspecs
            specs.each do |spec|
              spec.default_subspecs.each do |subspec_name|
                specs_by_platform[platform.name].push(spec.subspec_by_name("#{spec.name}/#{subspec_name}"))
              end
            end
          end

          # Let's remove any duplicated specs
          specs_by_platform[platform.name].uniq!(&:name)
        end
        specs_by_platform
      end

      def podfile(specs_by_platform)
        ps = @platforms
        
        Pod::Podfile.new do
          install! 'cocoapods', integrate_targets: false
          use_frameworks!

          ps.each do |p|
            next if specs_by_platform[p.name].empty?
            
            platform_version = specs_by_platform[p.name].map { |spec| Pod::Version.new(spec.deployment_target(p.name) || "0") }.max
            
            target "Target_for_#{p.name}" do
              platform p.name, platform_version
              specs_by_platform[p.name].each { |spec| pod spec.name, spec.version }
            end
          end
        end
      end

      def generate_podfile_file(specs_by_platform, path)
        podfile = "install! 'cocoapods', integrate_targets: false\n"
        podfile += "use_frameworks!\n"

        @platforms.each do |platform|
          next if specs_by_platform[platform.name].empty?

          platform_version = specs_by_platform[platform.name].map { |spec| Pod::Version.new(spec.deployment_target(platform.name) || "0") }
          platform_version = platform_version.max

          podfile += "\ntarget 'Target_for_#{platform.name}' do\n"
          podfile += "\tplatform :#{platform.name}, '#{platform_version}'\n"
          specs_by_platform[platform.name].each { |spec| podfile += "\tpod '#{spec.name}', '#{spec.version}'\n" }
          podfile += "end\n"
        end
        
        podfile_pathname = Pathname.new(path)
        podfile_pathname.dirname.mkpath
        podfile_pathname.write(podfile)
      end
    end
  end
end
