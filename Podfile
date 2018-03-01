# Uncomment the next line to define a global platform for your project
platform :ios, '11'

target 'Here & Now' do
  use_frameworks!

  # Pods for Here & Now
  pod 'RxSwift', '~> 4.1'
  pod 'RxCocoa', '~> 4.1'
  pod 'EasyPeasy', '~> 1.6'
  pod 'GoogleMaps', '~> 2.6'

  target 'Here & NowTests' do
    inherit! :search_paths
    # Pods for testing
    pod 'Mockingjay', '~> 2.0'
    pod 'RxBlocking', '~> 4.1'
  end

  target 'Here & NowUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        if target.name == 'Embassy'
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_OPTIMIZATION_LEVEL'] = '-Onone'
            end
        end
    end
end
