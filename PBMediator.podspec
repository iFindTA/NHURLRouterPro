Pod::Spec.new do |s|

  s.name         = "PBMediator"
  s.version      = "0.0.5"
  s.summary      = "PBMediator is an Objc Wrapper for components communication."
  s.homepage     = "https://github.com/iFindTA/NHURLRouterPro"
  s.description  = "Between components’s communication over url routes some like flask’s route mechanism that warpper by Objc, and for ios"
  s.license      = "MIT(LICENSE)"
  s.author             = { "nanhujiaju" => "nanhujiaju@163.com" }
  s.platform     = :ios, "7.0"
  s.source       = { :git => "https://github.com/iFindTA/NHURLRouterPro.git", :tag => s.version.to_s }
  s.source_files  = "NHURLRouterPro/PBRouter/**/*"
  s.public_header_files = "NHURLRouterPro/PBRouter/**/*.h"

  s.framework  = "UIKit","Foundation"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  s.requires_arc = true
  # s.dependency "JSONKit", "~> 1.4"
  end

