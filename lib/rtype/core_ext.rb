# true or false
module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

Any = BasicObject

class Object
	include ::Rtype::MethodAnnotator
end

module Kernel
private
	def _rtype_proxy
		unless @_rtype_proxy
			@_rtype_proxy = ::Rtype::RtypeProxy.new
			prepend @_rtype_proxy
		end
		@_rtype_proxy
	end

	# Makes the method typed
	# 
	# With 'annotation mode', this method works for both instance method and singleton method (class method).
	# Without it, this method only works for instance method.
	# 
	# @param [#to_sym, nil] method_name The name of method. If nil, annotation mode works
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @note Annotation mode doesn't work in the outside of module
	# @raise [ArgumentError] If method_name is nil in the outside of module
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype(method_name=nil, type_sig_info)
		if is_a?(Module)
			if method_name.nil?
				::Rtype::assert_valid_type_sig(type_sig_info)
				_rtype_proxy.annotation_mode = true
				_rtype_proxy.annotation_type_sig = type_sig_info
				nil
			else
				::Rtype::define_typed_method(self, method_name, type_sig_info)
			end
		else
			if method_name.nil?
				raise ArgumentError, "Annotation mode doesn't work in the outside of module"
			else
				rtype_self(method_name, type_sig_info)
			end
		end
	end

	# Makes the singleton method (class method) typed
	# 
	# @param [#to_sym] method_name
	# @param [Hash] type_sig_info A type signature. e.g. [Integer] => Any
	# @return [void]
	# 
	# @raise [ArgumentError] If method_name is nil
	# @raise [TypeSignatureError] If type_sig_info is invalid
	def rtype_self(method_name, type_sig_info)
		::Rtype.define_typed_method(singleton_class, method_name, type_sig_info)
	end
	
	# Calls `attr_accessor` if the accessor method(getter/setter) is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype
	def rtype_accessor(*names, type_behavior)
		rtype_reader(*names, type_behavior)
		rtype_writer(*names, type_behavior)
	end
	
	# Calls `attr_accessor` if the accessor method(getter/setter) is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_accessor_self(*names, type_behavior)
		rtype_reader_self(*names, type_behavior)
		rtype_writer_self(*names, type_behavior)
	end
	
	# Calls `attr_reader` if the getter method is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype
	def rtype_reader(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(name)
				attr_reader name
			end

			if is_a?(Module)
				::Rtype::define_typed_reader(self, name, type_behavior)
			else
				rtype_reader_self(name, type_behavior)
			end
		end
		nil
	end
	
	# Calls `attr_reader` if the getter method is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_reader_self(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(name)
				singleton_class.send(:attr_reader, name)
			end
			::Rtype::define_typed_reader(singleton_class, name, type_behavior)
		end
		nil
	end
	
	# Calls `attr_writer` if the setter method is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype
	def rtype_writer(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(:"#{name}=")
				attr_writer name
			end

			if is_a?(Module)
				::Rtype::define_typed_writer(self, name, type_behavior)
			else
				rtype_reader_self(name, type_behavior)
			end
		end
		nil
	end
	
	# Calls `attr_writer` if the setter method is not defined.
	# and makes it typed.
	# 
	# @param [Array<#to_sym>] names
	# @param type_behavior A type behavior
	# @return [void]
	# 
	# @raise [ArgumentError] If names contains nil
	# @raise [TypeSignatureError] If type_behavior is invalid
	# @see #rtype_self
	def rtype_writer_self(*names, type_behavior)
		names.each do |name|
			raise ArgumentError, "names contains nil" if name.nil?
			
			name = name.to_sym
			if !respond_to?(:"#{name}=")
				singleton_class.send(:attr_writer, name)
			end
			::Rtype::define_typed_writer(singleton_class, name, type_behavior)
		end
		nil
	end
end

class Method
	# @return [Boolean] Whether the method is typed with rtype
	def typed?
		!!::Rtype.type_signatures[owner][name]
	end

	# @return [TypeSignature]
	def type_signature
		::Rtype.type_signatures[owner][name]
	end

	# @return [Hash]
	# @see TypeSignature#info
	def type_info
		::Rtype.type_signatures[owner][name].info
	end
	
	# @return [Array, Hash]
	def argument_type
		::Rtype.type_signatures[owner][name].argument_type
	end

	# @return A type behavior
	def return_type
		::Rtype.type_signatures[owner][name].return_type
	end
end
