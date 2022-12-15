require File.expand_path('../../spec_helper', __FILE__)
require 'cocoapods-podfile-generator/version.rb'

module Pod
  PODS = { 
    "Firebase": "10.0.0",
    "FBSDKCoreKit": "15.0.0",
    "FBSDKLoginKit": "15.0.0",
    "FBSDKShareKit": "15.0.0",
  }

  describe Command::Podfile do
    describe 'CLAide' do
      it 'registers it self' do
        Command.parse(%w{ podfile }).should.be.instance_of Command::Podfile
      end

      describe "Validate the command" do
        # it "is well-formed" do
        #   lambda { Command.parse(%W{ podfile #{PODS.keys.first}:#{PODS.values.first} }).validate! }
        #     .should.not.raise()
        # end

        # it "parses multiple Pod arguments" do
        #   pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
        #   lambda { Command.parse(["podfile", *pod_args]).validate! }
        #     .should.not.raise()
        # end

        # it "parses a file correctly" do
        #   lambda { Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt }).validate! }
        #     .should.not.raise()
        # end

        # it "fails when no pods are given" do
        #   lambda { Command.parse(%W{ podfile }).validate! }
        #     .should.raise(CLAide::Help)
        #     .message.should.match(/You must give a Pod argument/)
        # end
  
        # it "fails when a bad Pod argument is given" do
        #   lambda { Command.parse(%W{ podfile #{PODS.keys.first}:#{PODS.values.first} #{PODS.keys.last}: }).validate! }
        #     .should.raise(CLAide::Help)
        #     .message.should.match(/There was a problem parsing the argument/)
        # end
  
        # it "fails when the text file given does not exist" do
        #   lambda { Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Non_existing_file.txt }).validate! }
        #     .should.raise(CLAide::Help)
        #     .message.should.match(/The file was not found/)
        # end

        # it "fails when there's a bad line to parse in a text file" do
        #   lambda { Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Bad_Pods_Format.txt }).validate! }
        #     .should.raise(CLAide::Help)
        #     .message.should.match(/There was a problem parsing the line/)
        # end

        # it "fails when a Pod as an argument does not exist" do
        #   lambda { Command.parse(%W{ podfile NonExistingPod:10.0.0 }).validate! }
        #     .should.raise(PodfileGeneratorInformative)
        #     .message.should.match(/There was a problem/)
        # end

        # it "fails when a Pod in a file does not exist" do
        #   lambda { Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Non_Existing_Pod.txt }).validate! }
        #     .should.raise(PodfileGeneratorInformative)
        #     .message.should.match(/There was a problem/)
        # end
      end

      describe "Test the command" do
        require 'pathname'
        
        before do
          @default_podfile_pathname = Pathname.new("Podfile")
          @default_podfile_pathname.delete if @default_podfile_pathname.exist?
          @podfile_pathname = Pathname.new("spec/test/Podfile")
          @podfile_pathname.delete if @podfile_pathname.exist?
        end

        it "generates the Podfile with one argument at the default path" do
          podfile = Command.parse(%W{ podfile #{PODS.keys.first}:#{PODS.values.first} })
          podfile.validate!
          podfile.run
          @default_podfile_pathname.exist?.should.be.true?
          @default_podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile with multiple arguments at the default path" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", *pod_args])
          podfile.validate!
          podfile.run
          @default_podfile_pathname.exist?.should.be.true?
          @default_podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile with one argument at a custom path" do
          podfile = Command.parse(%W{ podfile #{PODS.keys.first}:#{PODS.values.first} --#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname} })
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile with multiple arguments at a custom path" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", *pod_args, "--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname}"])
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile from a text file at the default path" do
          podfile = Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt })
          podfile.validate!
          podfile.run
          @default_podfile_pathname.exist?.should.be.true?
          @default_podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile from a text file at a custom path" do
          podfile = Command.parse(%W{ podfile --#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt --#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname} })
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile from multiple arguments and a text file at the default path" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", *pod_args, "--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt"])
          podfile.validate!
          podfile.run
          @default_podfile_pathname.exist?.should.be.true?
          @default_podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile from multiple arguments and a text file at a custom path" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", *pod_args, "--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt", "--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname}"])
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile including the default subspecs" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", *pod_args, "--#{CocoapodsPodfileGenerator::INCLUDE_DEFAULT_SUBSPECS_FLAG_NAME}", "--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt", "--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname}"])
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end

        it "generates the Podfile including all the subspecs" do
          pod_args = PODS.keys.map { |key| "#{key}:#{PODS[key]}" }
          podfile = Command.parse(["podfile", "Firebase:10.0.0", "--#{CocoapodsPodfileGenerator::INCLUDE_ALL_SUBSPECS_FLAG_NAME}", "--#{CocoapodsPodfileGenerator::FILE_OPTION_NAME}=./spec/Pods.txt", "--#{CocoapodsPodfileGenerator::OUTPUT_OPTION_NAME}=#{@podfile_pathname}"])
          podfile.validate!
          podfile.run
          @podfile_pathname.exist?.should.be.true?
          @podfile_pathname.empty?.should.be.false?
        end
      end
    end
  end
end

