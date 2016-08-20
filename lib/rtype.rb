if Object.const_defined?(:RUBY_ENGINE)
	case RUBY_ENGINE
	when "jruby"
		begin
			require 'java'
			require 'rtype/rtype_java'
			# puts "Rtype with Java extension"
		rescue LoadError
			# puts "Rtype without native extension"
		end
	when "ruby"
		begin
			require "rtype/rtype_native"
			# puts "Rtype with C native extension"
		rescue LoadError
			# puts "Rtype without native extension"
		end
	end
end

require_relative 'rtype/rtype_proxy'
require_relative 'rtype/method_annotator'
require_relative 'rtype/core_ext'
require_relative 'rtype/version'
require_relative 'rtype/type_signature_error'
require_relative 'rtype/argument_type_error'
require_relative 'rtype/return_type_error'
require_relative 'rtype/type_signature'
require_relative 'rtype/behavior'

module Rtype
	extend self

	# This is just 'information'
	# Any change of this doesn't affect type checking
	@@type_signatures = Hash.new

	# Makes the method typed
	# @param owner Owner of the method
	# @param [#to_sym] method_name
	# @param [Hash] type_sig_info A type signature. e.g. `[Integer, Float] => Float`
	# @return [void]
	# 
	# @raise [ArgumentError] If method_name is nil
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def define_typed_method(owner, method_name, type_sig_info)
		method_name = method_name.to_sym
		raise ArgumentError, "method_name is nil" if method_name.nil?
		assert_valid_type_sig(type_sig_info)

		el = type_sig_info.first
		arg_sig = el[0]
		return_sig = el[1]

		if arg_sig.is_a?(Array)
			expected_args = arg_sig.dup
			if expected_args.last.is_a?(Hash)
				expected_kwargs = expected_args.pop
			else
				expected_kwargs = {}
			end
		elsif arg_sig.is_a?(Hash)
			expected_args = []
			expected_kwargs = arg_sig
		end

		sig = TypeSignature.new
		sig.argument_type = arg_sig
		sig.return_type = return_sig
		unless @@type_signatures.key?(owner)
			@@type_signatures[owner] = {}
		end
		@@type_signatures[owner][method_name] = sig

		define_typed_method_to_proxy(owner, method_name, expected_args, expected_kwargs, return_sig)
	end
	
	# @param owner Owner of the accessor
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_accessor(owner, name, type_behavior)
		define_typed_reader(owner, name, type_behavior)
		define_typed_writer(owner, name, type_behavior)
	end
	
	# @param owner Owner of the getter
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_reader(owner, name, type_behavior)
		raise ArgumentError, "name is nil" if name.nil?
		valid?(type_behavior, nil)
		define_typed_method owner, name.to_sym, [] => type_behavior
	end
	
	# @param owner Owner of the setter
	# @param [#to_sym] name
	# @param type_behavior A type behavior. e.g. Integer
	# @return [void]
	# 
	# @raise [ArgumentError] If name is nil
	# @raise [TypeSignatureError]
	def define_typed_writer(owner, name, type_behavior)
		raise ArgumentError, "name is nil" if name.nil?
		valid?(type_behavior, nil)
		define_typed_method owner, :"#{name.to_sym}=", [type_behavior] => Any
	end

	# This is just 'information'
	# Any change of this doesn't affect type checking
	# 
	# @return [Hash]
	# @note type_signatures[owner][method_name]
	def type_signatures
		@@type_signatures
	end

=begin
	def assert_keyword_arguments_type(expected_kwargs, kwargs)
		kwargs.each do |key, value|
			expected = expected_kwargs[key]
			unless expected.nil?
				unless valid?(expected, value)
					raise ArgumentTypeError, "for '#{key}' argument:\n" + type_error_message(expected, value)
				end
			end
		end
	end
=end

	# @param [Integer] idx
	# @param expected A type behavior
	# @param value
	# @return [String] A error message
	# 
	# @raise [ArgumentError] If expected is invalid
	def arg_type_error_message(idx, expected, value)
		"#{arg_message(idx)}\n" + type_error_message(expected, value)
	end

	# @param [String, Symbol] key
	# @param expected A type behavior
	# @param value
	# @return [String] A error message
	# 
	# @raise [ArgumentError] If expected is invalid
	def kwarg_type_error_message(key, expected, value)
		"#{kwarg_message(key)}\n" + type_error_message(expected, value)
	end
	
	# @return [String]
	def arg_message(idx)
		"for #{ordinalize_number(idx+1)} argument:"
	end

	# @return [String]
	def kwarg_message(key)
		"for '#{key}' argument:"
	end

	# Returns a error message for the pair of type behavior and value
	# 
	# @param expected A type behavior
	# @param value
	# @return [String] error message
	# 
	# @note This method doesn't check the value is valid
	# @raise [TypeSignatureError] If expected is invalid
	def type_error_message(expected, value)
		case expected
		when Rtype::Behavior::Base
			expected.error_message(value)
		when Module
			"Expected #{value.inspect} to be a #{expected}"
		when Symbol
			"Expected #{value.inspect} to respond to :#{expected}"
		when Regexp
			"Expected stringified #{value.inspect} to match regexp #{expected.inspect}"
		when Range
			"Expected #{value.inspect} to be included in range #{expected.inspect}"
		when Array
			arr = expected.map { |e| type_error_message(e, value) }
			arr.join("\nOR ")
		when Hash
			if value.is_a?(Hash)
				arr = []
				expected.each do |k, v|
					if v.is_a?(Array) || v.is_a?(Hash)
						arr << "- #{k} : {\n" + type_error_message(v, value[k]) + "\n}"
					else
						arr << "- #{k} : " + type_error_message(v, value[k])
					end
				end
				"Expected #{value.inspect} to be a hash with #{expected.length} elements:\n" + arr.join("\n")
			else
				"Expected #{value.inspect} to be a hash"
			end
		when Proc
			"Expected #{value.inspect} to return a truthy value for proc #{expected}"
		when true
			"Expected #{value.inspect} to be a truthy value"
		when false
			"Expected #{value.inspect} to be a falsy value"
		when nil # for return
			"Expected #{value.inspect} to be nil"
		else
			raise TypeSignatureError, "Invalid type behavior #{expected}"
		end
	end

	# Checks the type signature is valid
	# 
	# e.g.
	# `[Integer] => Any` is valid.
	# `[Integer]` or `Any` are invalid
	# 
	# @param sig A type signature
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_type_sig(sig)
		unless sig.is_a?(Hash)
			raise TypeSignatureError, "Invalid type signature: type signature is not hash"
		end
		if sig.empty?
			raise TypeSignatureError, "Invalid type signature: type signature is empty hash"
		end
		assert_valid_arguments_type_sig(sig.first[0])
		assert_valid_return_type_sig(sig.first[1])
	end

	# Checks the arguments type signature is valid
	# 
	# e.g.
	# `[Integer]`, `{key: "value"}` are valid.
	# `Integer` is invalid
	# 
	# @param sig A arguments type signature
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_arguments_type_sig(sig)
		if sig.is_a?(Array)
			sig = sig.dup
			if sig.last.is_a?(Hash)
				kwargs = sig.pop
			else
				kwargs = {}
			end
			sig.each { |e| assert_valid_argument_type_sig_element(e) }
			if kwargs.keys.any? { |e| !e.is_a?(Symbol) }
				raise TypeSignatureError, "Invalid type signature: keyword arguments contain non-symbol key"
			end
			kwargs.each_value { |e| assert_valid_argument_type_sig_element(e) }
		elsif sig.is_a?(Hash)
			if sig.keys.any? { |e| !e.is_a?(Symbol) }
				raise TypeSignatureError, "Invalid type signature: keyword arguments contain non-symbol key"
			end
			sig.each_value { |e| assert_valid_argument_type_sig_element(e) }
		else
			raise TypeSignatureError, "Invalid type signature: arguments type signature is neither array nor hash"
		end
	end

	# Checks the type behavior is valid
	# 
	# @param sig A type behavior
	# @raise [TypeSignatureError] If sig is invalid
	def assert_valid_argument_type_sig_element(sig)
		case sig
		when Rtype::Behavior::Base
		when Module
		when Symbol
		when Regexp
		when Range
		when Array
			sig.each do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Hash
			sig.each_value do |e|
				assert_valid_argument_type_sig_element(e)
			end
		when Proc
		when true
		when false
		when nil
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{sig}"
		end
	end

	# @see #assert_valid_argument_type_sig_element
	def assert_valid_return_type_sig(sig)
		assert_valid_argument_type_sig_element(sig)
	end
	
	unless respond_to?(:valid?)
	# Checks the value is valid for the type behavior
	# 
	# @param expected A type behavior
	# @param value
	# @return [Boolean]
	# 
	# @raise [TypeSignatureError] If expected is invalid
	def valid?(expected, value)
		case expected
		when Module
			value.is_a? expected
		when Symbol
			value.respond_to? expected
		when Regexp
			!!(expected =~ value.to_s)
		when Range
			expected.include?(value)
		when Hash
			return false unless value.is_a?(Hash)
			return false unless expected.keys == value.keys
			expected.all? { |k, v| valid?(v, value[k]) }
		when Array
			expected.any? { |e| valid?(e, value) }
		when Proc
			!!expected.call(value)
		when true
			!!value
		when false
			!value
		when Rtype::Behavior::Base
			expected.valid? value
		when nil
			value.nil?
		else
			raise TypeSignatureError, "Invalid type signature: Unknown type behavior #{expected}"
		end
	end
	end

	unless respond_to?(:assert_arguments_type)
	# Validates arguments
	# 
	# @param [Array] expected_args A type signature for non-keyword arguments
	# @param [Array] args
	# @return [void]
	# 
	# @raise [TypeSignatureError] If expected_args is invalid
	# @raise [ArgumentTypeError] If args is invalid
	def assert_arguments_type(expected_args, args)
		e_len = expected_args.length
		# `length.times` is faster than `each_with_index`
		args.length.times do |i|
			break if i >= e_len
			expected = expected_args[i]
			value = args[i]
			unless valid?(expected, value)
				raise ArgumentTypeError, "#{arg_message(i)}\n" + type_error_message(expected, value)
			end
		end
		nil
	end
	end

	unless respond_to?(:assert_arguments_type_with_keywords)
	# Validates arguments and keyword arguments
	# 
	# @param [Array] expected_args A type signature for non-keyword arguments
	# @param [Array] args Arguments
	# @param [Hash] expected_kwargs A type signature for keyword arguments
	# @param [Hash] kwargs Keword arguments
	# @return [void]
	# 
	# @raise [TypeSignatureError] If expected_args or expected_kwargs are invalid
	# @raise [ArgumentTypeError] If args or kwargs are invalid
	def assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
		e_len = expected_args.length
		# `length.times` is faster than `each_with_index`
		args.length.times do |i|
			break if i >= e_len
			expected = expected_args[i]
			value = args[i]
			unless valid?(expected, value)
				raise ArgumentTypeError, "#{arg_message(i)}\n" + type_error_message(expected, value)
			end
		end
		
		kwargs.each do |key, value|
			if expected_kwargs.key?(key)
				expected = expected_kwargs[key]
				unless valid?(expected, value)
					raise ArgumentTypeError, "#{kwarg_message(key)}\n" + type_error_message(expected, value)
				end
			end
		end
		nil
	end
	end

	# Validates result
	# 
	# @param expected A type behavior
	# @param result
	# @return [void]
	# 
	# @raise [TypeSignatureError] If expected is invalid
	# @raise [ReturnTypeError] If result is invalid
	unless respond_to?(:assert_return_type)
	def assert_return_type(expected, result)
		unless valid?(expected, result)
			raise ReturnTypeError, "for return:\n" + type_error_message(expected, result)
		end
		nil
	end
	end

private
	# @param owner
	# @param [Symbol] method_name
	# @param [Array] expected_args
	# @param [Hash] expected_kwargs
	# @param return_sig
	# @return [void]
	def define_typed_method_to_proxy(owner, method_name, expected_args, expected_kwargs, return_sig)
		priv = owner.private_method_defined?(method_name)
		prot = owner.protected_method_defined?(method_name)
		
		if expected_kwargs.empty?
			# `send` is faster than `method(...).call`
			owner.send(:_rtype_proxy).send :define_method, method_name do |*args, &block|
				::Rtype::assert_arguments_type(expected_args, args)
				result = super(*args, &block)
				::Rtype::assert_return_type(return_sig, result)
				result
			end
		else
			# `send` is faster than `method(...).call`
			owner.send(:_rtype_proxy).send :define_method, method_name do |*args, **kwargs, &block|
				::Rtype::assert_arguments_type_with_keywords(expected_args, args, expected_kwargs, kwargs)
				result = super(*args, **kwargs, &block)
				::Rtype::assert_return_type(return_sig, result)
				result
			end
		end
		
		if priv
			owner.send(:_rtype_proxy).send(:private, method_name)
		elsif prot
			owner.send(:_rtype_proxy).send(:protected, method_name)
		end
		nil
	end
	
	# @param [Integer] num
	# @return [String]
	def ordinalize_number(num)
	    if (11..13).include?(num % 100)
			"#{num}th"
	    else
			case num % 10
			when 1; "#{num}st"
			when 2; "#{num}nd"
			when 3; "#{num}rd"
			else "#{num}th"
			end
	    end
	end
end
