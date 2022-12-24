module CocoapodsPodfileGenerator
  VERSION = "0.5.0"
  SUMMARY = "A Cocoapods plugin to generate a Podfile file with the pods provided."
  DESCRIPTION = <<-DESC
    A Cocoapods plugin that helps you generate a Podfile file with the pods provided. 
    
    The plugin has the following features that will try to make your life easier when creating a Podfile:
    
    * Generate a target per each platform supported by the pods provided. You can control which platforms to support

    * Calculate the best minimum supported version for each platform
    
    * Generate the Podfile just with the pods provided or it can add for you the subspecs or dependecies needed for each pod provided
  DESC

  # CLAide Arguments
  POD_ARGUMENT_NAME = "POD_NAME:POD_VERSION"

  # CLAide Flags
  REGEX_FLAG_NAME = "regex"
  INCLUDE_DEPENDENCIES_FLAG_NAME = "include-dependencies"
  INCLUDE_DEFAULT_SUBSPECS_FLAG_NAME = "include-default-subspecs"
  INCLUDE_ALL_SUBSPECS_FLAG_NAME = "include-all-subspecs"
  INCLUDE_ANALYZE_FLAG_NAME = "include-analyze"
  
  # CLAide Options
  TEXT_FILE_OPTION_NAME = "text-file"
  JSON_FILE_OPTION_NAME = "json-file"
  PLATFORMS_OPTION_NAME = "platforms"
  OUTPUT_OPTION_NAME = "output"
end
