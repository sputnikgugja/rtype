module Rtype
	module Behavior
		class IntegerCheck < NumericCheck
			def valid?(value)
				if value.is_a?(Integer)
					@lambda.call(value)
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be an integer #{@condition} #{@x}"
			end
		end
	end
end
