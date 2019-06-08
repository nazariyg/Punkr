source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '11.0'

inhibit_all_warnings!
use_frameworks!


def pods
    pod 'ReactiveSwift', '5.0.1'
    pod 'ReactiveCocoa', '9.0.0'
    pod 'Result', '4.1.0'
    pod 'Cartography', '~> 3.0'
    pod 'Alamofire', '~> 4.7'
    pod 'Kingfisher', '~> 5.0'
    pod 'SwiftyBeaver'
    pod 'R.swift'
    pod 'SwiftLint'
end


target 'Punkr' do
    pods
end


target 'Core' do
    pods
end


target 'Cornerstones' do
    pods
end


post_install do |installer|
    installer.pods_project.targets.each do |target|

        # Disable bitcode.
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
        end

        # Explicitly set the Swift version for pods that Xcode may complain about.
        if ['ReactiveSwift', 'ReactiveCocoa', 'Result'].include? target.name
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '5'
            end
        end

    end
end
