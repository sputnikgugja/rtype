module Rtype
	module Behavior
		# Typed set behavior. empty set allowed
		class TypedSet < Base
			def initialize(type)
				@type = type
				Rtype.assert_valid_argument_type_sig_element(@type)
			end

			def valid?(value)
				if value.is_a?(Set)
					any = value.any? do |e|
						!Rtype::valid?(@type, e)
					end
					!any
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be a set with type #{@type.inspect}"
			end
		end
	end
end
