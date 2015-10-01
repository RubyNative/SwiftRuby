Pod::Spec.new do |s|
    s.name        = "RubyNative"
    s.version     = "0.1"
    s.summary     = "Port of Ruby api to Swift for scripting"
    s.homepage    = "https://github.com/RubyNative/RubyNative"
    s.social_media_url = "https://twitter.com/Injection4Xcode"
    s.documentation_url = "https://github.com/RubyNative/RubyNative"
    s.license     = { :type => "MIT" }
    s.authors     = { "johnno1962" => "native@johnholdsworth.com" }

    s.osx.deployment_target = "10.9"
    s.source   = { :git => "https://github.com/RubyNative/RubyNative.git", :tag => s.version }
    s.source_files = "*.{m,swift}"
end
