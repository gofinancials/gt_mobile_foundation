#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint gt_device_integrity.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'gt_device_integrity'
  s.version          = '0.0.1'
  s.summary          = 'Reports raw device-integrity signals (root, jailbreak, clone, emulator, installer, signature) for gt_mobile_foundation to judge.'
  s.description      = <<-DESC
Reports raw device-integrity signals (root, jailbreak, clone, emulator, installer, signature) for gt_mobile_foundation to judge.
                       DESC
  s.homepage         = 'https://github.com/gofinancials/gt_mobile_foundation'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'GoFinancials' => 'https://github.com/gofinancials' }
  s.source           = { :path => '.' }
  s.source_files = 'gt_device_integrity/Sources/gt_device_integrity/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '15.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'

  # If your plugin requires a privacy manifest, for example if it uses any
  # required reason APIs, update the PrivacyInfo.xcprivacy file to describe your
  # plugin's privacy impact, and then uncomment this line. For more information,
  # see https://developer.apple.com/documentation/bundleresources/privacy_manifest_files
  # s.resource_bundles = {'gt_device_integrity_privacy' => ['gt_device_integrity/Sources/gt_device_integrity/PrivacyInfo.xcprivacy']}
end
