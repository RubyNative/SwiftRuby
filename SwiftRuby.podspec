Pod::Spec.new do |s|
    s.name        = "SwiftRuby"
    s.version     = "1.0"
    s.summary     = "Port of Ruby api to Swift for scripting"
    s.homepage    = "https://github.com/RubyNative/SwiftRuby"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/RubyNative/SwiftRuby"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "ruby@johnholdsworth.com" }

    s.osx.deployment_target = "10.9"
    s.ios.deployment_target = "8.0"
    s.source   = { :git => "https://github.com/RubyNative/SwiftRuby.git", :tag => s.version }
    s.source_files = "*.{swift,h,m,map}"
end
