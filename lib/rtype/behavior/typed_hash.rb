module Rtype
	module Behavior
		# Typed hash behavior. empty hash allowed
		class TypedHash < Base
			def initialize(key_type, value_type)
				@ktype = key_type
				@vtype = value_type
				Rtype.assert_valid_argument_type_sig_element(@ktype)
				Rtype.assert_valid_argument_type_sig_element(@vtype)
			end

			def valid?(value)
				if value.is_a?(Hash)
					any = value.any? do |k, v|
						!Rtype::valid?(@ktype, k) ||
						!Rtype::valid?(@vtype, v)
					end
					!any
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be a hash with key type #{@ktype.inspect} and value type #{@vtype.inspect}"
			end
		end
	end
end
