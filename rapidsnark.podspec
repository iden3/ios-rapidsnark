#
# Be sure to run `pod lib lint rapidsnark.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'rapidsnark'
  s.version          = '0.0.1-alpha.2'
  s.summary          = 'Swift wrapper for the rapidsnark proof generation library.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This library is Swift wrapper for the [Rapidsnark](https://github.com/iden3/rapidsnark). It enables the
generation of proofs for specified circuits within an iOS environment.
                       DESC

  s.homepage         = 'https://github.com/iden3/ios-rapidsnark'
  s.license          = { :type => 'GNU', :file => 'COPYING' }
  s.author           = { 'Yaroslav Moria' => 'morya.yaroslav@gmail.com' }
  s.source           = { :git => 'https://github.com/iden3/ios-rapidsnark.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'

  s.swift_versions = ['5']

  s.pod_target_xcconfig = {
    'ONLY_ACTIVE_ARCH' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.user_target_xcconfig = {
    'ONLY_ACTIVE_ARCH' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }

  s.subspec 'C' do |c|
    c.source_files = 'Sources/C/**/*'
    c.vendored_frameworks = "Libs/Rapidsnark.xcframework"
    c.ios.vendored_frameworks = "Libs/Rapidsnark.xcframework"
  end

  s.subspec 'rapidsnark' do |rapidsnark|
    rapidsnark.source_files = 'Sources/rapidsnark/**/*'
    rapidsnark.dependency 'rapidsnark/C'
    rapidsnark.ios.dependency 'rapidsnark/C'
  end

  s.default_subspec = 'rapidsnark'
end
