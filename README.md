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
| `--template`                 | A Podfile file to be used as the template for the final Podfile. Add the `{{CPG}}` keyword somewhere within your template and that will be replaced with the generated targets. Example: `--template=path/to/template_file` |
| `--text-file`                | A text file containing the pods to add to the Podfile. Each row within the file should have the format: <POD_NAME>:<POD_VERSION>. Example: `--text-file=path/to/file.txt` |
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

## Use an existing Podfile as a template

The content of the Podfile file can be very simple (including only a few lines) or it can be quite complex (for example, adding custom code when using the `pre_install` hook).

To avoid adding a flag for each option supported by the `install!` method, or to add an option for adding your own code when using a hook, etc., the solution is that you bring your own Podfile into the scene. This way, you will have better control of all the options and code blocks you need to make your Podfile work.

In order to use your Podfile as a template, just add the keyword `{{CPG}}` where you need the targets created by this plugin. E.g., create the following Podfile:

```ruby
install! 'cocoapods', integrate_targets: false, generate_multiple_pod_projects: true
use_frameworks!

pre_install do |installer|
	installer.pod_targets.each do |pod|
	puts "Forcing a static_framework to false for #{pod.name}"
		if Pod::VERSION >= "1.7.0"
			if pod.build_as_static?
				def pod.build_as_static?; false end
				def pod.build_as_static_framework?; false end
				def pod.build_as_dynamic?; true end
				def pod.build_as_dynamic_framework?; true end
			end
		else
			def pod.static_framework?; false end
		end
	end
end

{{CPG}}
```

Then use it with the command

```sh
pod podfile Firebase:10.0.0 FBSDKCoreKit:15.0.0 --include-all-subspecs --template=Podfile
```

And you will get

```ruby
install! 'cocoapods', integrate_targets: false, generate_multiple_pod_projects: true
use_frameworks!

pre_install do |installer|
	installer.pod_targets.each do |pod|
	puts "Forcing a static_framework to false for #{pod.name}"
		if Pod::VERSION >= "1.7.0"
			if pod.build_as_static?
				def pod.build_as_static?; false end
				def pod.build_as_static_framework?; false end
				def pod.build_as_dynamic?; true end
				def pod.build_as_dynamic_framework?; true end
			end
		else
			def pod.static_framework?; false end
		end
	end
end

target 'Target_for_ios' do
	platform :ios, '12.0'
	pod 'Firebase', '10.0.0'
	pod 'FBSDKCoreKit', '15.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'Firebase/Analytics', '10.0.0'
	pod 'Firebase/AnalyticsWithAdIdSupport', '10.0.0'
	pod 'Firebase/AnalyticsWithoutAdIdSupport', '10.0.0'
	pod 'Firebase/ABTesting', '10.0.0'
	pod 'Firebase/AppDistribution', '10.0.0'
	pod 'Firebase/AppCheck', '10.0.0'
	pod 'Firebase/Auth', '10.0.0'
	pod 'Firebase/Crashlytics', '10.0.0'
	pod 'Firebase/Database', '10.0.0'
	pod 'Firebase/DynamicLinks', '10.0.0'
	pod 'Firebase/Firestore', '10.0.0'
	pod 'Firebase/Functions', '10.0.0'
	pod 'Firebase/InAppMessaging', '10.0.0'
	pod 'Firebase/Installations', '10.0.0'
	pod 'Firebase/Messaging', '10.0.0'
	pod 'Firebase/MLModelDownloader', '10.0.0'
	pod 'Firebase/Performance', '10.0.0'
	pod 'Firebase/RemoteConfig', '10.0.0'
	pod 'Firebase/Storage', '10.0.0'
end

target 'Target_for_osx' do
	platform :osx, '10.13'
	pod 'Firebase', '10.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'Firebase/Analytics', '10.0.0'
	pod 'Firebase/AnalyticsWithAdIdSupport', '10.0.0'
	pod 'Firebase/AnalyticsWithoutAdIdSupport', '10.0.0'
	pod 'Firebase/ABTesting', '10.0.0'
	pod 'Firebase/AppCheck', '10.0.0'
	pod 'Firebase/Auth', '10.0.0'
	pod 'Firebase/Crashlytics', '10.0.0'
	pod 'Firebase/Database', '10.0.0'
	pod 'Firebase/Firestore', '10.0.0'
	pod 'Firebase/Functions', '10.0.0'
	pod 'Firebase/Installations', '10.0.0'
	pod 'Firebase/Messaging', '10.0.0'
	pod 'Firebase/MLModelDownloader', '10.0.0'
	pod 'Firebase/RemoteConfig', '10.0.0'
	pod 'Firebase/Storage', '10.0.0'
end

target 'Target_for_tvos' do
	platform :tvos, '12.0'
	pod 'Firebase', '10.0.0'
	pod 'FBSDKCoreKit', '15.0.0'
	pod 'Firebase/Core', '10.0.0'
	pod 'Firebase/CoreOnly', '10.0.0'
	pod 'Firebase/Analytics', '10.0.0'
	pod 'Firebase/AnalyticsWithAdIdSupport', '10.0.0'
	pod 'Firebase/AnalyticsWithoutAdIdSupport', '10.0.0'
	pod 'Firebase/ABTesting', '10.0.0'
	pod 'Firebase/AppCheck', '10.0.0'
	pod 'Firebase/Auth', '10.0.0'
	pod 'Firebase/Crashlytics', '10.0.0'
	pod 'Firebase/Database', '10.0.0'
	pod 'Firebase/Firestore', '10.0.0'
	pod 'Firebase/Functions', '10.0.0'
	pod 'Firebase/InAppMessaging', '10.0.0'
	pod 'Firebase/Installations', '10.0.0'
	pod 'Firebase/Messaging', '10.0.0'
	pod 'Firebase/MLModelDownloader', '10.0.0'
	pod 'Firebase/Performance', '10.0.0'
	pod 'Firebase/RemoteConfig', '10.0.0'
	pod 'Firebase/Storage', '10.0.0'
end
```

## Known limitations

* Do not support pods with empty versions
* Does not support versions with optimistic operator (~>)
* Cannot pass custom options to a pod (E.g., `pod 'PonyDebugger', :configurations => ['Debug', 'Beta']` )
