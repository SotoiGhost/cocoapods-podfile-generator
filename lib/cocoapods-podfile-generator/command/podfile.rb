require 'cocoapods-podfile-generator/podfilegeneratorinformative'

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
          # ["--#{CocoapodsPodfileGenerator::INCLUDE_DEPENDENCIES_FLAG_NAME}", "Include each pod dependencies in the Podfile."],
          # ["--#{CocoapodsPodfileGenerator::IGNORE_DEFAULT_SUBSPECS_FLAG_NAME}", "Ignore the `default_subspecs` value of specs and include all the subspecs in the Podfile."],
          ["--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}", "A text file containing the pods to add to the Podfile. Each row within the file should have the format: <POD_NAME>,<POD_VERSION>. Example: --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=path/to/file.txt"],
          ["--#{CocoapodsPodfileGenerator::PLATFORMS_OPTION_NAME}", "Platforms to consider. If not set, all platforms supported by the pods will be used. A target will be generated per platform. Example: --#{CocoapodsPodfileGenerator::PLATFORMS_OPTION_NAME}=ios,tvos"],
          ["--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}", "Path where the Podfile will be saved. If not set, the Podfile will be saved where the command is running. Example: --#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=path/to/save/Podfile_name"],
        ].concat(super)
      end

      def initialize(argv)
        # Let's get all the command line arguments.
        @pods = {}
        @pods_args = argv.arguments!
        @use_regex = argv.flag?(CocoapodsPodfileGenerator::REGEX_FLAG_NAME)
        # @include_dependencies = argv.flag?(CocoapodsPodfileGenerator::INCLUDE_DEPENDENCIES_FLAG_NAME)
        # @ignore_default_subspecs = argv.flag?(CocoapodsPodfileGenerator::IGNORE_DEFAULT_SUBSPECS_FLAG_NAME)
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
        specs_by_platform = get_specs_by_platform(specs)
        generate_podfile_file(specs_by_platform, @podfile_output_path)
      end

      private

      # Parse a string line to a hash
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
        # spec.default_subspecs = [] if @ignore_default_subspecs
        spec
      end

      # Analyze and resolve all the specs needed for this spec
      # def resolve_dependencies_for_spec(spec)
      #   # Get all the subspecs of the spec
      #   specs_by_platform = {}
      #   @platforms.each do |platform|
      #     specs_by_platform[platform.name] = spec.recursive_subspecs.select { |s| s.supported_on_platform?(platform) }
      #   end

      #   podfile = podfile(spec, specs_by_platform)
      #   resolved_specs = Pod::Installer::Analyzer.new(config.sandbox, podfile).analyze.specs_by_target

      #   @platforms.each do |platform|
      #     key = resolved_specs.keys.find { |key| key.name.end_with?(platform.name.to_s) }
      #     next if key.nil?

      #     if @include_dependencies
      #       specs_by_platform[platform.name] = resolved_specs[key]
      #     else
      #       pod_names = [spec.name]
      #       pod_names += spec.dependencies(platform).map(&:name)
      #       pod_names += specs_by_platform[platform.name].map(&:name)
      #       pod_names += specs_by_platform[platform.name].map { |spec| spec.dependencies(platform).map(&:name) }.flatten
      #       pod_names = pod_names.uniq

      #       specs_by_platform[platform.name] = resolved_specs[key].select { |spec| pod_names.include?(spec.name) }
      #     end
      #   end

      #   specs_by_platform
      # end

      # def podfile(spec, specs_by_platform)
      #   ps = @platforms
      #   pod_name = spec.name
      #   pod_version = spec.version.to_s
        
      #   Pod::Podfile.new do
      #     install! 'cocoapods', integrate_targets: false
      #     use_frameworks!

      #     ps.each do |p|
      #       next if not spec.supported_on_platform?(p)
            
      #       platform_version = [Pod::Version.new(spec.deployment_target(p.name) || "0")]
      #       platform_version += specs_by_platform[p.name].map { |spec| Pod::Version.new(spec.deployment_target(p.name) || "0") }
      #       platform_version = platform_version.max
            
      #       target "#{pod_name}_#{p.name}" do
      #         platform p.name, platform_version
      #         pod pod_name, pod_version
      #         specs_by_platform[p.name].each { |spec| pod spec.name, spec.version } if not specs_by_platform[p.name].empty?
      #       end
      #     end
      #   end
      # end

      def resolve_platforms_if_needed(specs)
        # Get all the supported platforms without the OS version if no platforms are specified
        @platforms = specs
          .map { |spec| spec.available_platforms.map(&:name) }
          .flatten
          .uniq if @platforms.empty?
        @platforms.map! { |platform| Pod::Platform.new(platform) }
      end

      def get_specs_by_platform(specs)
        specs_by_platform = {}
        @platforms.each do |platform|
          specs_by_platform[platform.name] = specs.select { |spec| spec.supported_on_platform?(platform) }
        end
        specs_by_platform
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
