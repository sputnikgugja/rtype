$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "rtype/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
	s.name = "rtype-native"
	s.version = Rtype::VERSION
	s.authors = ["Sputnik Gugja"]
	s.email = ["sputnikgugja@gmail.com"]
	s.homepage = "https://github.com/sputnikgugja/rtype"
	s.summary = "C native extension for Rtype"
	s.description = "C native extension for Rtype"
	s.licenses = "MIT"

	s.test_files = Dir["{test,spec}/**/*"]
	s.require_paths = ["lib"] # by default it is ["lib"]

	s.add_dependency "rtype", Rtype::VERSION

	s.add_development_dependency "rake", "~> 11.0"
	s.add_development_dependency "rspec"
	s.add_development_dependency "coveralls"

	s.required_ruby_version = "~> 2.1"

	s.files = Dir["benchmark/*", "Rakefile", "Gemfile", "README.md", "LICENSE", 'ext/**/*.{rb,c,h}']
	s.extensions = Dir['ext/**/extconf.rb']
end
