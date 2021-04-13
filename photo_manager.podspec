Pod::Spec.new do |s|
    s.name = 'photo_manager'
    s.summary = 'Core code of flutter_photo_manager.'
    s.description = 'Core code of flutter_photo_manager.'
    s.version = '1.0.0'
    s.license = 'Apache License 2.0'
    s.homepage = 'https://github.com/CaiJingLong/flutter_photo_manager'
    s.authors = {'Cai JingLong' => 'cjl_spy@163.com'}
    s.source = {:git => 'https://github.com/CaiJingLong/flutter_photo_manager.git', :tag => "apple-#{s.version}",}

    s.ios.deployment_target = '9.0'
    s.osx.deployment_target = '10.15'

    s.source_files = 'apple_code/photo_manager/Classes'
end