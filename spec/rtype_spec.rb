require_relative 'spec_helper'

describe Rtype do
	let(:klass) do
		Class.new do
			attr_accessor :value

			def initialize
				@value = 123
			end

			def return_arg(obj)
				obj
			end

			def two_args(a, b)
			end

			def three_args(a, b, c)
			end

			def three_kwargs(a:, b:, c:)
			end

			def return_nil(obj)
				nil
			end

			def sum(a, b)
				a + b
			end

			def kwarg(a:)
				a
			end

			def sum_kwargs(a:, b:)
				a + b
			end

			def arg_and_kwarg(a, b:)
			end

			def arg_and_kwargs(a, b:, c:)
			end

			def args_and_kwargs(a, b, c:, d:)
			end
			
			public
			def public_func
			end

			protected
			def protected_func
			end

			private
			def private_func
			end
		end
	end

	let(:instance) do
		klass.new
	end

	describe 'Kernel#rtype' do
		context "with annotation mode" do
			it "works with instance method" do
				class AnnotationTest
					rtype [String] => Any
					def test(str)
					end
				end
				expect {
					AnnotationTest.new.test(123)
				}.to raise_error Rtype::ArgumentTypeError
			end
			it "works with class method" do
				class AnnotationTest
					rtype [String] => Any
					def self.class_method_test(str)
					end
				end
				expect {
					AnnotationTest::class_method_test(123)
				}.to raise_error Rtype::ArgumentTypeError
			end
			context "outside of module" do
				it "doesn't works" do
					expect {
						rtype [String] => Any
						def annotation_test(str)
						end
					}.to raise_error ArgumentError
				end
			end
		end

		it "outside of module" do
			rtype :test_args, [String] => Any
			def test_args(str)
			end

			expect {test_args 123}.to raise_error Rtype::ArgumentTypeError

			rtype :test_return, [] => String
			def test_return
				369
			end

			expect {test_return}.to raise_error Rtype::ReturnTypeError
		end

		it "in module" do
			class TestClass
				rtype :test_args, [String] => Any
				def test_args(str)
				end
			end

			expect {TestClass.new.test_args 123}.to raise_error Rtype::ArgumentTypeError

			class TestClass
				rtype :test_return, [] => String
				def test_return
					369
				end
			end

			expect {TestClass.new.test_return}.to raise_error Rtype::ReturnTypeError
		end
	end

	it "Kernel#rtype_self" do
		class TestClass
			rtype_self :static_test_args, [String] => Any
			def self.static_test_args(str)
			end
		end

		expect {TestClass::static_test_args 123}.to raise_error Rtype::ArgumentTypeError

		class TestClass
			rtype_self :static_test_return, [] => String
			def self.static_test_return
				369
			end
		end

		expect {TestClass::static_test_return}.to raise_error Rtype::ReturnTypeError
	end

	it 'Kernel#rtype_accessor' do
		class AccessorTestClass
			rtype_accessor :value, :value2, String

			def initialize
				@value = 123
				@value2 = 123
			end
		end
		expect {AccessorTestClass.new.value = 123}.to raise_error Rtype::ArgumentTypeError
		expect {AccessorTestClass.new.value}.to raise_error Rtype::ReturnTypeError
		expect {AccessorTestClass.new.value2 = 123}.to raise_error Rtype::ArgumentTypeError
		expect {AccessorTestClass.new.value2}.to raise_error Rtype::ReturnTypeError
	end

	it 'Kernel#rtype_accessor_self' do
		class AccessorTestClass
			@@value = 123
			@@value2 = 123
			rtype_accessor_self :value, :value2, String
		end
		expect {AccessorTestClass::value = 123}.to raise_error Rtype::ArgumentTypeError
		expect {AccessorTestClass::value}.to raise_error Rtype::ReturnTypeError
		expect {AccessorTestClass::value2 = 123}.to raise_error Rtype::ArgumentTypeError
		expect {AccessorTestClass::value2}.to raise_error Rtype::ReturnTypeError
	end

	it 'Kernel#rtype_reader' do
		class ReaderTestClass
			rtype_reader :value, :value2, String

			def initialize
				@value = 123
				@value2 = 123
			end
		end
		expect {ReaderTestClass.new.value}.to raise_error Rtype::ReturnTypeError
		expect {ReaderTestClass.new.value2}.to raise_error Rtype::ReturnTypeError
	end

	it 'Kernel#rtype_reader_self' do
		class ReaderTestClass
			@@value = 123
			@@value2 = 123
			rtype_reader_self :value, :value2, String
		end
		expect {ReaderTestClass::value}.to raise_error Rtype::ReturnTypeError
		expect {ReaderTestClass::value2}.to raise_error Rtype::ReturnTypeError
	end

	it 'Kernel#rtype_writer' do
		class WriterTestClass
			rtype_writer :value, :value2, String

			def initialize
				@value = 123
				@value2 = 123
			end
		end
		expect {WriterTestClass.new.value = 123}.to raise_error Rtype::ArgumentTypeError
		expect {WriterTestClass.new.value2 = 123}.to raise_error Rtype::ArgumentTypeError
	end

	it 'Kernel#rtype_writer_self' do
		class WriterTestClass
			@@value = 123
			@@value2 = 123
			rtype_writer_self :value, :value2, String
		end
		expect {WriterTestClass::value = 123}.to raise_error Rtype::ArgumentTypeError
		expect {WriterTestClass::value2 = 123}.to raise_error Rtype::ArgumentTypeError
	end

	it 'Kernel#float_accessor' do
		class FloatAccessorTestClass
			float_accessor :float, :int
			
			def initialize
				@float = 10.0
				@int = 10
			end
		end
		
		float_accessor_test = FloatAccessorTestClass.new
		
		float_accessor_test.float
		expect {float_accessor_test.int}.to raise_error Rtype::ReturnTypeError
		float_accessor_test.float = 5.0
		float_accessor_test.float = 5
		expect(float_accessor_test.float).to eql(5.0) # be(expected) => passes if actual.eql?(expected)
		expect(float_accessor_test.float).not_to eql(5)
	end

	it 'Kernel#bool_accessor' do
		class BoolAccessorTestClass
			bool_accessor :state, :invalid_var
			
			def initialize
				@state = false
				@invalid_var = 123
			end
		end
		
		bool_accessor_test = BoolAccessorTestClass.new
		
		bool_accessor_test.state?
		expect {bool_accessor_test.state}.to raise_error NoMethodError
		expect(bool_accessor_test.state?).to eql(false)
		bool_accessor_test.state = true
		expect(bool_accessor_test.state?).to eql(true)
		expect {bool_accessor_test.state = 123}.to raise_error Rtype::ArgumentTypeError
		expect {bool_accessor_test.invalid_var?}.to raise_error Rtype::ReturnTypeError
	end

	describe 'Test type behaviors' do
		describe 'Module' do
			it "is right" do
				klass.send :rtype, :return_arg, [String] => Any
				instance.return_arg("This is a string!")
			end
			it "is wrong" do
				klass.send :rtype, :return_arg, [String] => Any
				expect {instance.return_arg(123)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => String
				expect {instance.return_nil("This is a string!")}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Symbol' do
			it "is right" do
				klass.send :rtype, :return_arg, [:to_i] => Any
				instance.return_arg(123)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [:to_i] => Any
				expect {instance.return_arg(true)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => :odd?
				expect {instance.return_nil(123)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Regexp' do
			it "is right" do
				klass.send :rtype, :return_arg, [/cuba/] => Any
				instance.return_arg("cuba")
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [/cuba/] => Any
				expect {instance.return_arg("brazil")}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => /cuba/
				expect {instance.return_nil("cuba")}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Range' do
			it "is right" do
				klass.send :rtype, :return_arg, [1..10] => Any
				instance.return_arg(5)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [1..10] => Any
				expect {
					instance.return_arg(1001)
				}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => 1..10
				expect {
					instance.return_nil(5)
				}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Array' do
			it "is right" do
				klass.send :rtype, :return_arg, [[:to_i]] => Any
				instance.return_arg(123)

				klass.send :rtype, :return_arg, [[String, Integer]] => Any
				instance.return_arg("str")
				instance.return_arg(123)
				
				klass.send :rtype, :return_arg, [] => [String, Integer]
				instance.return_arg("str")
				instance.return_arg(123)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [[String, Integer]] => Any
				expect {
					instance.return_arg(nil)
				}.to raise_error Rtype::ArgumentTypeError

				klass.send :rtype, :return_arg, [[String]] => Any
				expect {
					instance.return_arg(123)
				}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => [String, Integer]
				expect {instance.return_arg(true)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Hash' do
			it "is right" do
				klass.send :rtype, :return_arg, [{k: Integer}, {}] => Any
				instance.return_arg({k: 123})
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [{k: Integer}, {}] => Any
				expect {
					instance.return_arg({k: "str"})
				}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => {k: Integer}
				expect { instance.return_arg({k: "str"}) }.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Proc' do
			it "is right" do
				klass.send :rtype, :return_arg, [->(arg){!arg.nil?}] => Any
				instance.return_arg(123)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [->(arg){!arg.nil?}] => Any
				expect {instance.return_arg(nil)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => ->(arg){!arg.nil?}
				expect {instance.return_nil(123)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'true' do
			it "is right" do
				klass.send :rtype, :return_arg, [true] => Any
				instance.return_arg(true)
				instance.return_arg(123)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [true] => Any
				expect {instance.return_arg(false)}.to raise_error Rtype::ArgumentTypeError
				expect {instance.return_arg(nil)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => true
				expect {instance.return_arg(false)}.to raise_error Rtype::ReturnTypeError
				expect {instance.return_arg(nil)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'false' do
			it "is right" do
				klass.send :rtype, :return_arg, [false] => Any
				instance.return_arg(false)
				instance.return_arg(nil)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [false] => Any
				expect {instance.return_arg(true)}.to raise_error Rtype::ArgumentTypeError
				expect {instance.return_arg(123)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => false
				expect {instance.return_arg(true)}.to raise_error Rtype::ReturnTypeError
				expect {instance.return_arg(123)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'nil' do
			it "for return" do
				klass.send :rtype, :return_nil, [] => nil
				instance.return_nil(123)

				klass.send :rtype, :return_arg, [] => nil
				expect {instance.return_arg(123)}.to raise_error Rtype::ReturnTypeError
			end
			it "for args" do
				klass.send :rtype, :return_arg, [nil] => Any
				instance.return_arg(nil)
				expect {
					instance.return_arg(123)
				}.to raise_error Rtype::ArgumentTypeError
			end
		end

		describe 'Special type behaviors' do
			describe 'Rtype::Behavior::And' do
				it 'module singleton method' do
					klass.send :rtype, :return_nil, [Rtype::and(:to_i, :chars)] => nil
					instance.return_nil("Hello")
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
				end

				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::And[:to_i, :chars] ] => nil
					instance.return_nil("Hello")
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method' do
					klass.send :rtype, :return_nil, [ :to_i.and(:chars) ] => nil
					instance.return_nil("Hello")
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
				end
			end

			describe 'Rtype::Behavior::Nilable' do
				it 'module singleton method' do
					klass.send :rtype, :return_nil, [Rtype::nilable(Integer)] => nil
					instance.return_nil(nil)
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::Nilable[Integer] ] => nil
					instance.return_nil(nil)
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method :nilable' do
					klass.send :rtype, :return_nil, [Integer.nilable] => nil
					instance.return_nil(nil)
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method :or_nil' do
					klass.send :rtype, :return_nil, [Integer.or_nil] => nil
					instance.return_nil(nil)
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end
			end

			describe 'Rtype::Behavior::Not' do
				it 'module singleton method' do
					klass.send :rtype, :return_nil, [Rtype::not(String)] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::Not[String] ] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method' do
					klass.send :rtype, :return_nil, [ String.not ] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end
			end

			describe 'Rtype::Behavior::Xor' do
				it 'module singleton method' do
					klass.send :rtype, :return_nil, [Rtype::xor(:to_i, String)] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::Xor[:to_i, String] ] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method' do
					klass.send :rtype, :return_nil, [ :to_i.xor(String) ] => nil
					instance.return_nil(123)
					expect {instance.return_nil("abc")}.to raise_error Rtype::ArgumentTypeError
				end
			end
			
			describe 'Rtype::Behavior::TypedArray' do
				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::TypedArray[Integer] ] => nil
					instance.return_nil([123])
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil([1.0])}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method (Array::of)' do
					klass.send :rtype, :return_nil, [ Array.of(Integer) ] => nil
					instance.return_nil([123])
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil([1.0])}.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'complicated type sig' do
					klass.send :rtype, :return_nil, [ Array.of(:to_i.and(:chars)) ] => nil
					instance.return_nil(["hello"])
					expect {instance.return_nil("hello")}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil([123])}.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'allows empty array' do
					klass.send :rtype, :return_nil, [ Array.of(Integer) ] => nil
					instance.return_nil([])
				end
			end
			
			describe 'Rtype::Behavior::TypedSet' do
				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::TypedSet[Integer] ] => nil
					instance.return_nil( Set.new([123]) )
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(Set.new([1.0])) }.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method (Set::of)' do
					klass.send :rtype, :return_nil, [ Set.of(Integer) ] => nil
					instance.return_nil( Set.new([123]) )
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(Set.new([1.0])) }.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'complicated type sig' do
					klass.send :rtype, :return_nil, [ Set.of(:to_i.and(:chars)) ] => nil
					instance.return_nil( Set.new(["hello"]) )
					expect {instance.return_nil("hello")}.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(Set.new([123])) }.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'allows empty set' do
					klass.send :rtype, :return_nil, [ Set.of(Integer) ] => nil
					instance.return_nil(Set.new)
				end
			end
			
			describe 'Rtype::Behavior::TypedHash' do
				it 'class singleton [] method' do
					klass.send :rtype, :return_nil, [ Rtype::Behavior::TypedHash[Symbol, Integer] ] => nil
					instance.return_nil( {key: 123} )
					expect {instance.return_nil(:key)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil( {"key" => 123} )}.to raise_error Rtype::ArgumentTypeError
				end

				it 'core extension method (Hash::of)' do
					klass.send :rtype, :return_nil, [ Hash.of(Symbol, Integer) ] => nil
					instance.return_nil( {key: 123} )
					expect {instance.return_nil(:key)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil( {"key" => 123} )}.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'complicated type sig' do
					klass.send :rtype, :return_nil, [ Hash.of(:to_i.and(:chars), :to_i.and(:chars)) ] => nil
					instance.return_nil( {"key" => "val"} )
					expect {instance.return_nil("hello")}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil( {key: "val"} )}.to raise_error Rtype::ArgumentTypeError
					expect {instance.return_nil( {"key" => :val} )}.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'allows empty hash' do
					klass.send :rtype, :return_nil, [ Hash.of(Symbol, Integer) ] => nil
					instance.return_nil({})
				end
			end
			
			describe 'Numeric check' do
				it 'Num (Numeric)' do
					klass.send :rtype, :return_nil, [Num >= 0] => Any
					expect { instance.return_nil("hello") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(-1) }.to raise_error Rtype::ArgumentTypeError
					instance.return_nil(2)
					instance.return_nil(2.0)
					
					klass.send :rtype, :return_nil, [Num > 0] => Any
					expect { instance.return_nil("non numeric") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Num < 0] => Any
					expect { instance.return_nil("non numeric") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Num <= 0] => Any
					expect { instance.return_nil("non numeric") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(1) }.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'Int (Integer)' do
					klass.send :rtype, :return_nil, [Int >= 0] => Any
					expect { instance.return_nil("hello") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(1.0) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(-1) }.to raise_error Rtype::ArgumentTypeError
					instance.return_nil(2)
					
					klass.send :rtype, :return_nil, [Int > 0] => Any
					expect { instance.return_nil(1.0) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Int < 0] => Any
					expect { instance.return_nil(-1.0) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Int <= 0] => Any
					expect { instance.return_nil(0.0) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(1) }.to raise_error Rtype::ArgumentTypeError
				end
				
				it 'Flo (Float)' do
					klass.send :rtype, :return_nil, [Flo >= 0] => Any
					expect { instance.return_nil("hello") }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(1) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(-1.0) }.to raise_error Rtype::ArgumentTypeError
					instance.return_nil(2.0)
					
					klass.send :rtype, :return_nil, [Flo > 0] => Any
					expect { instance.return_nil(1) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0.0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Flo < 0] => Any
					expect { instance.return_nil(-1) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(0.0) }.to raise_error Rtype::ArgumentTypeError
					
					klass.send :rtype, :return_nil, [Flo <= 0] => Any
					expect { instance.return_nil(0) }.to raise_error Rtype::ArgumentTypeError
					expect { instance.return_nil(1.0) }.to raise_error Rtype::ArgumentTypeError
				end
			end
		end
	end

	describe 'Signature' do
		describe 'check arguments' do
			it 'nothing' do
				klass.send :rtype, :sum, [] => Any
				instance.sum(1, 2)
				instance.sum(1, 2.0)
				instance.sum(1.0, 2.0)
				instance.sum("a", "b")
			end

			it 'two' do
				klass.send :rtype, :sum, [Integer, Integer] => Any
				expect {instance.sum(1, 2.0)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'two hash' do
				klass.send :rtype, :two_args, [{k: Integer}, {k: Integer}, {}] => Any
				instance.two_args({k: 123}, {k: 456})
				expect {
					instance.two_args({k: 123}, {})
				}.to raise_error Rtype::ArgumentTypeError
				expect {
					instance.two_args({k: 123}, 456)
				}.to raise_error Rtype::ArgumentTypeError
				expect {
					instance.two_args({k: 123}, {k: "str"})
				}.to raise_error Rtype::ArgumentTypeError
			end

			it 'one keyword argument' do
				klass.send :rtype, :kwarg, {a: Float} => Any
				expect {instance.kwarg(a: 1)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'two keyword argument' do
				klass.send :rtype, :sum_kwargs, {a: Integer, b: Float} => Any
				expect {instance.sum_kwargs(a: 1, b: 2)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'one with one keyword argument' do
				klass.send :rtype, :arg_and_kwarg, [Integer, {b: Float}] => Any
				expect {instance.arg_and_kwarg(1, b: 2)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'one with two keyword argument' do
				klass.send :rtype, :arg_and_kwargs, [Integer, {c: String, d: String}] => Any
				expect {instance.arg_and_kwargs(1, b: 2, c: 3)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'two with two keyword argument' do
				klass.send :rtype, :args_and_kwargs, [Integer, Integer, {c: String, d: String}] => Any
				expect {instance.args_and_kwargs(1, 2, c: 3, d: 4)}.to raise_error Rtype::ArgumentTypeError
			end

			it 'string key could not be used for keyword argument' do
				expect {
					klass.send :rtype, :kwarg, {'a' => Float} => Any
				}.to raise_error Rtype::TypeSignatureError
			end

			it 'only symbol key is used for keyword argument' do
				klass.send :rtype, :kwarg, {:a => Float} => Any
				expect {instance.kwarg(a: 1)}.to raise_error Rtype::ArgumentTypeError
				expect {instance.kwarg(:a => 1)}.to raise_error Rtype::ArgumentTypeError
			end

			context 'when hash is not last element' do
				it 'is hash-type argument, not keyword argument' do
					klass.send :rtype, :return_arg, [{a: String}, {}] => Any
					expect {
						instance.return_arg({a: 123})
					}.to raise_error Rtype::ArgumentTypeError
				end
			end

			it 'hash-type argument and keyword argument' do
				klass.send :rtype, :arg_and_kwarg, [{a: String}, {b: String}] => Any
				expect {
					instance.arg_and_kwarg({a: 123}, b: "str")
				}.to raise_error Rtype::ArgumentTypeError
				expect {
					instance.arg_and_kwarg({a: "str"}, b: 123)
				}.to raise_error Rtype::ArgumentTypeError
			end
		end

		describe 'check return' do
			it 'Any' do
				klass.send :rtype, :return_arg, [] => Any
				instance.return_arg("str")
			end

			it 'Array' do
				klass.send :rtype, :return_arg, [] => [Integer, Float]
				expect {instance.return_arg("str")}.to raise_error Rtype::ReturnTypeError
			end
		end

		it 'check arguments and return value' do
			klass.send :rtype, :return_nil, [Float] => nil
			expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
			klass.send :rtype, :return_nil, [Integer] => Integer
			expect {instance.return_nil(123)}.to raise_error Rtype::ReturnTypeError
		end

		describe 'wrong case' do
			describe 'invalid type signature' do
				it 'invalid arguments type signature' do
					expect {
						klass.send :rtype, :return_arg, Any => nil
					}.to raise_error Rtype::TypeSignatureError
				end
				it 'invalid return type signature' do
					expect {
						klass.send :rtype, :return_arg, [] => 123
					}.to raise_error Rtype::TypeSignatureError
				end

				it 'invalid type behavior in arguments' do
					expect {
						klass.send :rtype, :sum_kwargs, [{a: 123}, {b: Integer}] => Any
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :return_arg, [123] => Any
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :return_arg, ["abc"] => Any
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :kwarg, {a: 123} => Any
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :kwarg, {a: {b: 123}} => Any
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :kwarg, {Object.new => Integer} => Any
					}.to raise_error Rtype::TypeSignatureError
				end

				it 'invalid type behavior in return' do
					expect {
						klass.send :rtype, :return_arg, [] => 123
					}.to raise_error Rtype::TypeSignatureError
					expect {
						klass.send :rtype, :return_arg, [] => "abc"
					}.to raise_error Rtype::TypeSignatureError
				end

				context "with annotation mode" do
					it 'works' do
						expect {
							class AnnotationTest
								rtype [String, 123] => Any
								def invalid_test(arg)
								end
							end
						}.to raise_error Rtype::TypeSignatureError
					end
				end
			end
		end
	end

	describe "Implementation" do
		it 'can be called before method definition' do
			class TestClass
				rtype :method_def, [Integer] => Any
				def method_def(i)
				end
			end
			expect {
				TestClass.new.method_def("abc")
			}.to raise_error Rtype::ArgumentTypeError
		end

		it 'can be called after method definition' do
			class TestClass
				def method_def_2(i)
				end
				rtype :method_def_2, [Integer] => Any
			end
			expect {
				TestClass.new.method_def_2("abc")
			}.to raise_error Rtype::ArgumentTypeError
		end

		it 'method name can be both symbol and string' do
			class TestClass
				rtype 'method_def_3', [Integer] => Any
				def method_def_3(i)
				end
				rtype :method_def_4, [Integer] => Any
				def method_def_4(i)
				end
			end
			expect {
				TestClass.new.method_def_3("abc")
			}.to raise_error Rtype::ArgumentTypeError
			expect {
				TestClass.new.method_def_4("abc")
			}.to raise_error Rtype::ArgumentTypeError
		end

		describe 'method visibility works' do
			it 'protected' do
				klass.send :rtype, :protected_func, [] => Any
				expect {instance.protected_func}.to raise_error NoMethodError
			end
			it 'private' do
				klass.send :rtype, :private_func, [] => Any
				expect {instance.private_func}.to raise_error NoMethodError
			end
			it 'public' do
				klass.send :rtype, :public_func, [] => Any
				instance.public_func
			end
		end

		context 'with empty argument signature' do
			it 'accept any arguments' do
				klass.send :rtype, :three_args, [] => Any
				instance.three_args("abc", 123, 456)
			end
		end

		context 'when args length is more than arg signature length' do
			it 'type checking ignore rest args' do
				klass.send :rtype, :three_args, [String] => Any
				instance.three_args("abc", 123, 456)
			end
		end

		context 'when keyword args contain a key not configured to rtype' do
			it 'type checking ignore the key' do
				klass.send :rtype, :three_kwargs, {a: String} => Any
				instance.three_kwargs(a: "abc", b: 123, c: 456)
			end
		end

		context 'when hash type argument contain a key not configured to rtype' do
			it 'raises error' do
				klass.send :rtype, :return_arg, [{a: String}, {}] => Any
				expect {
					instance.return_arg({a: "str", b: "str"})
				}.to raise_error Rtype::ArgumentTypeError
			end
		end

		it "One rtype annotation affect only one method" do
			class AnnotationTest
				rtype [String] => Any
				def one(str)
				end

				def two(str)
				end
			end
			expect {
				AnnotationTest.new.one(123)
			}.to raise_error Rtype::ArgumentTypeError
			AnnotationTest.new.two(123)
		end

		it "One rtype annotation affect only one method, regardless of instance method or class method" do
			class AnnotationTest2
				rtype [String] => Any
				def self.static_one(str)
				end

				def inst_one(str)
				end

				def self.static_two(str)
				end
			end
			expect {
				AnnotationTest2::static_one(123)
			}.to raise_error Rtype::ArgumentTypeError
			AnnotationTest2.new.inst_one(123)
			AnnotationTest2::static_two(123)
		end

		context 'when rtype signature duplicated' do
			it 'the latest have priority' do
				class PriorityTest1
					rtype :test_priority, [String] => Any
					def test_priority(arg)
					end
					rtype :test_priority, [Integer] => Any
				end
				
				PriorityTest1.new.test_priority(1)
				expect { PriorityTest1.new.test_priority("str") }.to raise_error Rtype::ArgumentTypeError
			end
			
			it 'annotation mode have priority in contemporaneous signatures' do
				class PriorityTest2
					rtype :test_priority, [String] => Any
					rtype [Integer] => Any
					def test_priority(arg)
					end
				end
				
				PriorityTest2.new.test_priority(1)
				expect { PriorityTest2.new.test_priority("str") }.to raise_error Rtype::ArgumentTypeError
			end
		end
	end

	describe "Call Rtype`s static method directly" do
		it 'Rtype::define_typed_method' do
			Rtype::define_typed_method klass, :return_arg, [String] => Any
			expect {instance.return_arg(123)}.to raise_error Rtype::ArgumentTypeError
		end

		it 'Rtype::define_typed_accessor' do
			Rtype::define_typed_accessor klass, :value, String
			expect { instance.value = 123 }.to raise_error Rtype::ArgumentTypeError
			expect { instance.value }.to raise_error Rtype::ReturnTypeError
		end
		
		it 'Rtype::valid?' do
			expect(
				Rtype::valid?(String, "str")
			).to be true
			expect(
				Rtype::valid?(Integer, "str")
			).to be false
			expect {
				Rtype::valid?("Invalid type behavior", "Test Value")
			}.to raise_error Rtype::TypeSignatureError
		end
		
		it 'Rtype::assert_arguments_type' do
			expect {
				Rtype::assert_arguments_type([Integer, String], [123, 123])
			}.to raise_error Rtype::ArgumentTypeError
		end
		
		it 'Rtype::assert_arguments_type_with_keywords' do
			expect {
				Rtype::assert_arguments_type_with_keywords([Integer, String], [123, "abc"], {arg: String}, {arg: 123})
			}.to raise_error Rtype::ArgumentTypeError
		end
		
		it 'Rtype::assert_return_type' do
			expect {
				Rtype::assert_return_type nil, "No nil"
			}.to raise_error Rtype::ReturnTypeError
		end
		
		it 'Rtype::assert_valid_type_sig' do
			Rtype::assert_valid_type_sig([Integer, String] => Any)
			expect {
				Rtype::assert_valid_type_sig([Integer, String])
			}.to raise_error Rtype::TypeSignatureError
		end
		
		it 'Rtype::assert_valid_arguments_type_sig' do
			Rtype::assert_valid_arguments_type_sig([Integer, String])
			expect {
				Rtype::assert_valid_arguments_type_sig("[Integer, String]")
			}.to raise_error Rtype::TypeSignatureError
		end
		
		it 'Rtype::assert_valid_argument_type_sig_element' do
			Rtype::assert_valid_argument_type_sig_element(Integer)
			expect {
				Rtype::assert_valid_argument_type_sig_element("Integer")
			}.to raise_error Rtype::TypeSignatureError
		end
		
		it 'Rtype::assert_valid_return_type_sig' do
			Rtype::assert_valid_return_type_sig(Integer)
			expect {
				Rtype::assert_valid_return_type_sig("Integer")
			}.to raise_error Rtype::TypeSignatureError
		end
	end
end
