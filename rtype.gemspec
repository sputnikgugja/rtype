$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rtype/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "rtype"
  s.version = Rtype::VERSION
  s.authors = ["Sputnik Gugja"]
  s.email = ["sputnikgugja@gmail.com"]
  s.homepage = "https://github.com/sputnikgugja/rtype"
  s.summary = "Ruby with type"
  s.description = "The fastest type checking gem"
  s.licenses = "MIT"

  s.test_files = Dir["{test,spec}/**/*"]
  s.require_paths = ["lib"] # by default it is ["lib"]
  
  if defined?(JRUBY_VERSION)
    s.platform = "java"
    s.add_dependency "rtype-java", Rtype::VERSION
  end

  s.add_development_dependency "rake", "~> 11.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "coveralls"

  s.required_ruby_version = "~> 2.1"

  s.files = Dir["benchmark/*", "{lib}/**/*", "Rakefile", "Gemfile", "README.md", "LICENSE"]
end
