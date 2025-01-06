#
# Run `pod lib lint rapidsnark.podspec' to ensure this is a valid spec before submitting.

Pod::Spec.new do |s|
  s.name             = 'rapidsnark'
  s.version          = '0.0.1-beta.1'
  s.summary          = 'Swift wrapper for the rapidsnark proof generation library.'
  s.description      = <<-DESC
This library is Swift wrapper for the [Rapidsnark](https://github.com/iden3/rapidsnark). It enables the
generation of proofs for specified circuits within an iOS and macOS environment.
                       DESC
  s.homepage         = 'https://github.com/iden3/ios-rapidsnark'
  s.license          = {
      :type => 'MIT AND Apache-2.0',
      :files => ['LICENSE-MIT', 'LICENSE-APACHE']
    }
  s.authors          = {
      'Yaroslav Moria' => 'morya.yaroslav@gmail.com',
      'Dmytro Sukhyi' => 'dmytro.sukhiy@gmail.com'
    }
  s.source           = { :git => '../', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.14'

  s.swift_versions = ['5']

  s.pod_target_xcconfig = {
    'ONLY_ACTIVE_ARCH' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }
  s.user_target_xcconfig = {
    'ONLY_ACTIVE_ARCH' => 'YES',
    'CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES' => 'YES'
  }

  s.subspec 'rapidsnarkC' do |c|
    c.source_files = 'Sources/rapidsnarkC/**/*'
    c.vendored_frameworks = "Libs/Rapidsnark.xcframework"
  end

  s.subspec 'rapidsnark' do |rapidsnark|
    rapidsnark.source_files = 'Sources/rapidsnark/**/*'
    rapidsnark.dependency 'rapidsnark/rapidsnarkC'
  end

  s.default_subspec = 'rapidsnark'
end
