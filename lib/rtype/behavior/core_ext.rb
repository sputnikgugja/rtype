class Object
	# @return [Rtype::Behavior::And]
	def and(*others)
		::Rtype::and(self, *others)
	end

	# @return [Rtype::Behavior::Nilable]
	def nilable
		::Rtype::nilable(self)
	end
	alias_method :or_nil, :nilable

	# @return [Rtype::Behavior::Not]
	def not
		::Rtype::not(self)
	end

	# @return [Rtype::Behavior::Xor]
	def xor(*others)
		::Rtype::xor(self, *others)
	end
end

class Array
	# @return [Rtype::Behavior::TypedArray]
	def self.of(type_sig)
		::Rtype::Behavior::TypedArray.new(type_sig)
	end
	
	# @return [Rtype::Behavior::And]
	def comb
		::Rtype::Behavior::And[*self]
	end
end

class Set
	# @return [Rtype::Behavior::TypedSet]
	def self.of(type_sig)
		::Rtype::Behavior::TypedSet.new(type_sig)
	end
end

class Hash
	# @return [Rtype::Behavior::TypedHash]
	def self.of(key_type, value_type)
		::Rtype::Behavior::TypedHash.new(key_type, value_type)
	end
end

class Num
	# @param [Numeric] x
	# @return [Rtype::Behavior::NumericCheck]
	# @example Value must be a Numeric and > 2
	#   rtype [Num > 2] => Any
	def self.>(x)
		::Rtype::Behavior::NumericCheck.new(:>, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::NumericCheck]
	# @example Value must be a Numeric and > 2
	#   rtype [Num > 2] => Any
	def self.>=(x)
		::Rtype::Behavior::NumericCheck.new(:>=, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::NumericCheck]
	# @example Value must be a Numeric and > 2
	#   rtype [Num > 2] => Any
	def self.<(x)
		::Rtype::Behavior::NumericCheck.new(:<, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::NumericCheck]
	# @example Value must be a Numeric and > 2
	#   rtype [Num > 2] => Any
	def self.<=(x)
		::Rtype::Behavior::NumericCheck.new(:<=, x)
	end
	
	# @param [Numeric] x
	# @return [Rtype::Behavior::NumericCheck]
	# @example Value must be a Numeric and > 2
	#   rtype [Num > 2] => Any
	def self.==(x)
		::Rtype::Behavior::NumericCheck.new(:==, x)
	end
end

class Int
	# @param [Numeric] x
	# @return [Rtype::Behavior::IntegerCheck]
	# @example Value must be a Integer and > 2
	#   rtype [Int > 2] => Any
	def self.>(x)
		::Rtype::Behavior::IntegerCheck.new(:>, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::IntegerCheck]
	# @example Value must be a Integer and > 2
	#   rtype [Int > 2] => Any
	def self.>=(x)
		::Rtype::Behavior::IntegerCheck.new(:>=, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::IntegerCheck]
	# @example Value must be a Integer and > 2
	#   rtype [Int > 2] => Any
	def self.<(x)
		::Rtype::Behavior::IntegerCheck.new(:<, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::IntegerCheck]
	# @example Value must be a Integer and > 2
	#   rtype [Int > 2] => Any
	def self.<=(x)
		::Rtype::Behavior::IntegerCheck.new(:<=, x)
	end
	
	# @param [Numeric] x
	# @return [Rtype::Behavior::IntegerCheck]
	# @example Value must be a Integer and > 2
	#   rtype [Int > 2] => Any
	def self.==(x)
		::Rtype::Behavior::IntegerCheck.new(:==, x)
	end
end

class Flo
	# @param [Numeric] x
	# @return [Rtype::Behavior::FloatCheck]
	# @example Value must be a Float and > 2
	#   rtype [Flo > 2] => Any
	def self.>(x)
		::Rtype::Behavior::FloatCheck.new(:>, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::FloatCheck]
	# @example Value must be a Float and > 2
	#   rtype [Flo > 2] => Any
	def self.>=(x)
		::Rtype::Behavior::FloatCheck.new(:>=, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::FloatCheck]
	# @example Value must be a Float and > 2
	#   rtype [Flo > 2] => Any
	def self.<(x)
		::Rtype::Behavior::FloatCheck.new(:<, x)
	end

	# @param [Numeric] x
	# @return [Rtype::Behavior::FloatCheck]
	# @example Value must be a Float and > 2
	#   rtype [Flo > 2] => Any
	def self.<=(x)
		::Rtype::Behavior::FloatCheck.new(:<=, x)
	end
	
	# @param [Numeric] x
	# @return [Rtype::Behavior::FloatCheck]
	# @example Value must be a Float and > 2
	#   rtype [Flo > 2] => Any
	def self.==(x)
		::Rtype::Behavior::FloatCheck.new(:==, x)
	end
end
