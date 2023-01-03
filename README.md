# cocoapods-podfile-generator

A Cocoapods plugin that helps you generate a Podfile file with the pods provided. 
    
The plugin has the following features that will try to make your life easier for creating a Podfile:

* Generate a target per each platform supported by the pods provided. You can control which platforms to support
* Calculate the best minimum supported version for each platform
* Generate the Podfile just with the pods provided or it can add for you the subspecs or dependecies needed for each pod provided

## Installation

    $ gem install cocoapods-podfile-generator

## Usage

    $ pod podfile [POD_NAME:POD_VERSION ...]

You can pass some flags and options to generate some different tastes for the Podfile:

| Option name | Description |
|---|---|
| `--regex`                    | Interpret the pod names as a regular expression |
| `--include-dependencies`     | Include each pod's dependencies name in the Podfile. |
| `--include-default-subspecs` | Include the `default_subspecs` values in the Podfile if any. |
| `--include-all-subspecs`     | Include all the subspecs in the Podfile if any. |
| `--include-analyze`          | Let cocoapods resolve the necessary dependencies for the provided pods and include them in the Podfile. |
| `--text-file`                     | A text file containing the pods to add to the Podfile. Each row within the file should have the format: <POD_NAME>:<POD_VERSION>. Example: `--text-file=path/to/file.txt` |
| `--platforms`                | Platforms to consider. If not set, all platforms supported by the pods will be used. A target will be generated per platform. Example: `--platforms=ios,tvos` |
| `--output`                   | Path where the Podfile will be saved. If not set, the Podfile will be saved where the command is running. Example: `--output=path/to/save/Podfile_name` |

## Example

Running the following command:

    $ pod podfile Firebase:10.0.0 FBSDKShareKit:15.0.0 --include-default-subspecs --include-dependencies         

will generate the following output:

```ruby
install! 'cocoapods', integrate_targets: false
use_frameworks!

target 'Target_for_ios' do
	platform :ios, '12.0'
	pod 'Firebase', '10.0.0'
	pod 'FBSDKShareKit', '15.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'FBSDKCoreKit', '15.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'FirebaseAnalytics', '10.0.0'
end

target 'Target_for_osx' do
	platform :osx, '10.13'
	pod 'Firebase', '10.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'FirebaseAnalytics', '10.0.0'
end

target 'Target_for_tvos' do
	platform :tvos, '12.0'
	pod 'Firebase', '10.0.0'
	pod 'FBSDKShareKit', '15.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'FBSDKCoreKit', '15.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'FirebaseAnalytics', '10.0.0'
end
```

## Known limitations

* Does not support versions with optimistic operator (~>)
