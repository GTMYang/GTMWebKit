

Pod::Spec.new do |s|

  s.name         = "GTMWebKit"
  s.version      = "0.5"
  s.summary      = "swift 针对 WKWebKit 的封装"
  s.swift_version= "4.2"

  s.homepage     = "https://github.com/GTMYang/GTMWebKit"

  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { "GTMYang" => "17757128523@163.com" }


  s.source       = { :git => "https://github.com/GTMYang/GTMWebKit.git", :tag => s.version }
  s.source_files = 'GTMWebKit/*.{h,swift}'
  s.resources    = 'GTMWebKit/GTMWebKit.bundle'

  s.ios.deployment_target = '8.0'
  s.frameworks = 'UIKit','Foundation','WebKit'

# s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.0' }

end
