package_name = 'photo_manager'
pubspec = YAML.load_file(File.join('..', 'pubspec.yaml'))
library_version = pubspec['version'].gsub('+', '-')

Pod::Spec.new do |s|
  s.name             = package_name
  s.version          = library_version
  s.summary          = 'Photo management APIs for Flutter.'
  s.description      = <<-DESC
A Flutter plugin that provides assets abstraction management APIs.
                       DESC
  s.homepage         = 'https://github.com/fluttercandies/flutter_photo_manager'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'CaiJingLong' => 'cjl_spy@163.com' }
  s.source           = { :http => 'https://github.com/fluttercandies/flutter_photo_manager/tree/main/ios' }

  s.source_files = "#{package_name}/Sources/#{package_name}/**/*"
  s.public_header_files = "#{package_name}/Sources/#{package_name}/**/**/*.h"

  s.osx.dependency 'FlutterMacOS'
  s.ios.dependency 'Flutter'

  s.ios.frameworks = 'Photos', 'PhotosUI', 'CoreLocation'
  s.osx.frameworks = 'Photos', 'PhotosUI', 'CoreLocation'

  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.15'

  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.0'

  s.resource_bundles = {
    "#{package_name}_privacy" => [
      "#{package_name}/Sources/#{package_name}/Resources/PrivacyInfo.xcprivacy"
    ]
  }
end
