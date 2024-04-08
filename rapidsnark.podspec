#
# Be sure to run `pod lib lint rapidsnark.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'rapidsnark'
  s.version          = '0.1.0'
  s.summary          = 'A short description of rapidsnark.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/5eeman/rapidsnark-ios'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Yaroslav Moria' => 'morya.yaroslav@gmail.com' }
  s.source           = { :git => 'https://github.com/5eeman/rapidsnark-ios.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '12.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'

  s.pod_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }
  s.user_target_xcconfig = { 'ONLY_ACTIVE_ARCH' => 'YES' }

  s.static_framework = true

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
