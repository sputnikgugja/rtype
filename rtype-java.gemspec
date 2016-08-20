$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rtype/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = "rtype-java"
  s.version = Rtype::VERSION
  s.authors = ["Sputnik Gugja"]
  s.email = ["sputnikgugja@gmail.com"]
  s.homepage = "https://github.com/sputnikgugja/rtype"
  s.summary = "Java extension for Rtype"
  s.description = "Java extension for Rtype"
  s.licenses = 'MIT'

  s.test_files = Dir["{test,spec}/**/*"]
    # s.executables = s.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  s.require_paths = ["ext"] # by default it is ["lib"]

  s.platform = "java"

  # s.add_development_dependency "bundler", "~> 1.10"
  s.add_development_dependency "rake", "~> 11.0"
  s.add_development_dependency "rspec"
  s.add_development_dependency "coveralls"

  s.required_ruby_version = "~> 2.1"

  s.files = Dir["benchmark/*", "Rakefile", "Gemfile", "README.md", "LICENSE", 'ext/rtype/*.jar']
end
