# Uncomment the next line to define a global platform for your project
platform :ios, '11'

target 'HereAndNow' do
  use_frameworks!
  pod 'RxSwift', '~> 4.1'
  pod 'RxCocoa', '~> 4.1'
  pod 'EasyPeasy', '~> 1.6'
  pod 'GoogleMaps', '~> 2.6'

  target 'HereAndNowTests' do
    inherit! :search_paths
    pod 'Mockingjay', '~> 2.0'
    pod 'RxBlocking', '~> 4.1'
    pod 'Quick', '~> 1.2'
    pod 'Nimble', '~> 7.0'
  end

  target 'HereAndNowUITests' do
    inherit! :search_paths
    pod 'Quick', '~> 1.2'
    pod 'Nimble', '~> 7.0'
  end
end
