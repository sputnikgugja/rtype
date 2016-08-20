require 'coveralls'
Coveralls.wear!

require 'rtype'
require 'rspec'
require 'set'

if !Rtype::NATIVE_EXT_VERSION.nil?
	puts "Rtype with native extension"
elsif !Rtype::JAVA_EXT_VERSION.nil?
	puts "Rtype with java extension"
else
	puts "Rtype without native extension"
end
