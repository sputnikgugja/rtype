module Rtype
	module Behavior
		class NumericCheck < Base
			@@conditions = [
				:>, :<, :>=, :<=, :==
			]
			
			# @param [Symbol] condition
			# @param [Numeric] x
			def initialize(condition, x)
				raise ArgumentError, "Invalid condition '#{condition}'" unless @@conditions.include?(condition)
				raise ArgumentError, "x is not a Numeric" unless x.is_a?(Numeric)
				@condition = condition
				@x = x
				@lambda = case condition
					when :>
						lambda { |obj| obj > @x }
					when :<
						lambda { |obj| obj < @x }
					when :>=
						lambda { |obj| obj >= @x }
					when :<=
						lambda { |obj| obj <= @x }
					when :==
						lambda { |obj| obj == @x }
				end
			end
			
			def valid?(value)
				if value.is_a?(Numeric)
					@lambda.call(value)
				else
					false
				end
			end

			def error_message(value)
				"Expected #{value.inspect} to be a numeric #{@condition} #{@x}"
			end
		end
	end
end
