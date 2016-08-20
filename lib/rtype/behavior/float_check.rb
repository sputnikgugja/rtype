module Rtype
	module Behavior
		class FloatCheck < NumericCheck
			def valid?(value)
				if value.is_a?(Float)
					@lambda.call(value)
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be a float #{@condition} #{@x}"
			end
		end
	end
end
