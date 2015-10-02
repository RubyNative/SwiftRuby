Pod::Spec.new do |s|
    s.name        = "RubyKit"
    s.version     = "0.1"
    s.summary     = "Port of Ruby api to Swift for scripting"
    s.homepage    = "https://github.com/RubyNative/RubyKit"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/RubyNative/RubyKit"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "ruby@johnholdsworth.com" }

    s.osx.deployment_target = "10.9"
    s.source   = { :git => "https://github.com/RubyNative/RubyKit.git", :tag => s.version }
    s.source_files = "*.{m,swift}"
end
