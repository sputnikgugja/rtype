require_relative 'spec_helper'

describe Rtype do
	let(:klass) do
		Class.new do
			def return_arg(obj)
				obj
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
				expect {instance.return_arg(1001)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => 1..10
				expect {instance.return_nil(5)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'Array' do
			it "is right" do
				klass.send :rtype, :return_arg, [[:to_i, :to_i]] => Any
				instance.return_arg([123, 456])
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [[:to_i, :to_i]] => Any
				expect {instance.return_arg([123, true])}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => [:to_i, :to_i]
				expect {instance.return_arg(true)}.to raise_error Rtype::ReturnTypeError
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
				instance.return_arg(123)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [true] => Any
				expect {instance.return_arg(nil)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_nil, [Any] => true
				expect {instance.return_nil(123)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'false' do
			it "is right" do
				klass.send :rtype, :return_arg, [false] => Any
				instance.return_arg(nil)
			end
			it "is wrong args" do
				klass.send :rtype, :return_arg, [false] => Any
				expect {instance.return_arg(123)}.to raise_error Rtype::ArgumentTypeError
			end
			it "is wrong result" do
				klass.send :rtype, :return_arg, [Any] => false
				expect {instance.return_arg(123)}.to raise_error Rtype::ReturnTypeError
			end
		end

		describe 'nil' do
			it "is only for return" do
				klass.send :rtype, :return_nil, [] => nil
				instance.return_nil(123)

				klass.send :rtype, :return_arg, [] => nil
				expect {instance.return_arg(123)}.to raise_error Rtype::ReturnTypeError
			end
			it "could not be used for args" do
				expect {
					klass.send :rtype, :return_arg, [nil] => Any
				}.to raise_error Rtype::TypeSignatureError
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
		end

		describe 'check return' do
			it 'Any' do
				klass.send :rtype, :return_arg, [] => Any
				instance.return_arg("str")
			end

			it 'Array (tuple)' do
				klass.send :rtype, :return_arg, [] => [Integer, Float]
				expect {instance.return_arg([1, 2])}.to raise_error Rtype::ReturnTypeError
			end
		end

		it 'check arguments and return value' do
			klass.send :rtype, :return_nil, [Float] => nil
			expect {instance.return_nil(123)}.to raise_error Rtype::ArgumentTypeError
			klass.send :rtype, :return_nil, [Integer] => Integer
			expect {instance.return_nil(123)}.to raise_error Rtype::ReturnTypeError
		end

		describe 'wrong case' do
			describe 'invalid signature form' do
				it 'invalid argument signature' do
					expect {
						klass.send :rtype, :return_arg, Any => nil
					}.to raise_error Rtype::TypeSignatureError
				end
				it 'invalid return signature' do
					expect {
						klass.send :rtype, :return_arg, [] => {}
					}.to raise_error Rtype::TypeSignatureError
				end

				it 'invalid type behavior in arguments' do
					expect {
						klass.send :rtype, :sum_kwargs, [{a: Integer}, {b: Integer}] => Any
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
						klass.send :rtype, :kwarg, {a: {b: Integer}} => Any
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
				expect {instance.protected_func}.to raise_error NoMethodError
			end
			it 'private' do
				expect {instance.private_func}.to raise_error NoMethodError
			end
		end
	end
end
