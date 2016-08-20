# Rtype: ruby with type
[![Gem Version](https://badge.fury.io/rb/rtype.svg)](https://badge.fury.io/rb/rtype)
[![Build Status](https://travis-ci.org/sputnikgugja/rtype.svg?branch=master)](https://travis-ci.org/sputnikgugja/rtype)
[![Coverage Status](https://coveralls.io/repos/github/sputnikgugja/rtype/badge.svg?branch=master)](https://coveralls.io/github/sputnikgugja/rtype?branch=master)

```ruby
require 'rtype'

class Test
  rtype [:to_i, Numeric] => Numeric
  def sum(a, b)
    a.to_i + b
  end

  rtype({state: Boolean} => Boolean) # Hashes of Hashes params require () to prevent invalid syntax
  def self.invert(state:)
    !state
  end
end

Test.new.sum(123, "asd")
# (Rtype::ArgumentTypeError) for 2nd argument:
# Expected "asd" to be a Numeric

Test::invert(state: 0)
# (Rtype::ArgumentTypeError) for 'state' argument:
# Expected 0 to be a Boolean
```

## Requirements
- Ruby >= 2.1
  - If you need to use old ruby, see [rtype-legacy](https://github.com/sputnikgugja/rtype-legacy) for ruby 1.9+
- MRI
  - If C native extension is used. otherwise it is not required
- JRuby (JRuby 9000+)
  - If Java extension is used. otherwise it is not required

## Features
- Provides type checking for arguments and return
- Provides type checking for [Keyword Argument](#keyword-argument)
- [Type checking for hash elements](#hash)
- [Duck Typing](#duck-typing)
- [Typed Array](#typed-array)
- [Numeric check](#special-behaviors). e.g. `Int >= 0`
- Custom type behavior
- ...

## Installation
Run `gem install rtype` or add `gem 'rtype'` to your `Gemfile`

And add to your `.rb` source file:
```ruby
require 'rtype'
```

### Native extension
Rtype itself is pure-ruby gem. but you can make it more faster by using native extension.

#### Native extension for MRI
Run
```ruby
gem install rtype-native
```
or add to your `Gemfile`:
```ruby
gem 'rtype-native'
```
then, Rtype uses it. (**Do not** `require 'rtype-native'`)

#### Java extension for JRuby
Run
```ruby
gem install rtype-java
```
or add to your `Gemfile`:
```ruby
gem 'rtype-java'
```
then, Rtype uses it. (**Do not** `require 'rtype-java'`)

## Usage

### Supported Type Behaviors
- `Module` : Value must be of this module (`is_a?`)
  - `Any` : Alias for `BasicObject` (means Any Object)
  - `Boolean` : `true` or `false`
- `Symbol` : Value must respond to a method with this name
- `Regexp` : Value must match this regexp pattern
- `Range` : Value must be included in this range
- `Array` : Value can be any type in this array
- `Proc` : Value must return a truthy value for this proc
- `true` : Value must be truthy
- `false` : Value must be falsy
- `nil` : Value must be nil
- `Hash`
  - Value must be a hash
  - Each of elements must be valid
  - Keys of the value must be equal to keys of this hash
  - **String** key is **different** from **symbol** key
  - vs. Keyword arguments (e.g.)
    - `[{}]` is **not** hash argument. it is keyword argument, because its position is last
    - `[{}, {}]` is hash argument (first) and keyword argument (second)
    - `[{}, {}, {}]` is two hash argument (first, second) and keyword argument (last)
    - `{}` is keyword argument. non-keyword arguments must be in array.
  - Of course, nested hash works
  - Example: [Hash](#hash)
  
- [Special Behaviors](#special-behaviors)
  - `TypedArray`, `Num, Int, Flo`, `And`, `Xor`, `Not`, `Nilable`

### Examples

#### Basic
```ruby
require 'rtype'

class Example
  rtype [Integer] => nil
  def test(i)
  end
  
  rtype [Any] => nil
  def any_type_arg(arg)
  end
  
  rtype [] => Integer
  def return_type_test
    "not integer"
  end
end

e = Example.new
e.test("not integer")
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected "not integer" to be a Integer

e.any_type_arg("Any argument!") # Works

e.return_type_test
# (Rtype::ReturnTypeError) for return:
# Expected "not integer" to be a Integer
```

#### Keyword argument
```ruby
require 'rtype'

class Example
  rtype {name: String} => Any
  def say_your_name(name:)
    puts "My name is #{name}"
  end
  
  # Mixing positional arguments and keyword arguments
  rtype [String, {age: Integer}] => Any
  def name_and_age(name, age:)
    puts "Name: #{name}, Age: #{age}"
  end
end

Example.new.say_your_name(name: "Babo") # My name is Babo
Example.new.name_and_age("Bamboo", age: 100) # Name: Bamboo, Age: 100

Example.new.say_your_name(name: 12345)
# (Rtype::ArgumentTypeError) for 'name' argument:
# Expected 12345 to be a String
```

#### Duck typing
```ruby
require 'rtype'

class Duck
  rtype [:to_i] => Any
  def says(i)
    puts "duck:" + " quack"*i.to_i
  end
end

Duck.new.says("2") # duck: quack quack
```

#### Array
```ruby
rtype :ruby!, [[String, Integer]] => Any
def ruby!(arg)
	puts "ruby!"
end

func("str") # ruby!
func(123) # ruby!

func(nil)
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected nil to be a String
# OR Expected nil to be a Integer
```

#### Hash
```ruby
# last hash element is keyword arguments
rtype :func, [{msg: String}, {}] => Any
def func(hash)
  puts hash[:msg]
end

func({})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {} to be a hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: 123})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>123} to be a hash with 1 elements:
# - msg : Expected 123 to be a String

func({msg: "hello", key: 'value'})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {:msg=>"hello", :key=>"value"} to be a hash with 1 elements:
# - msg : Expected "hello" to be a String

func({"msg" => "hello hash"})
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected {"msg"=>"hello hash"} to be a hash with 1 elements:
# - msg : Expected nil to be a String

func({msg: "hello hash"}) # hello hash
```

#### rtype with attr_accessor
`rtype_accessor` : calls `attr_accessor` if the accessor method(getter/setter) is not defined. and makes it typed

You can use `rtype_accessor_self` for static accessor.

```ruby
require 'rtype'

class Example
  rtype_accessor :value, String

  def initialize
    @value = 456
  end
end

Example.new.value = 123
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected 123 to be a String

Example.new.value
# (Rtype::ReturnTypeError) for return:
# Expected 456 to be a String
```

#### Typed Array
```ruby
### TEST 1 ###
class Test
	rtype [Array.of(Integer)] => Any
	def sum(args)
		num = 0
		args.each { |e| num += e }
	end
end

sum([1, 2, 3]) # => 6

sum([1.0, 2, 3])
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1.0, 2, 3] to be an array with type Integer"
```

```ruby
### TEST 2 ###
class Test
	rtype [ Array.of([Integer, Float]) ] => Any
	def sum(args)
		num = 0
		args.each { |e| num += e }
	end
end

sum([1, 2, 3]) # => 6
sum([1.0, 2, 3]) # => 6.0
```

#### `rtype`
```ruby
require 'rtype'

class Example
  # Recommended. With annotation mode (no method name required)
  rtype [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end

  # Works (with specifying method name)
  rtype :hello_world, [Integer, String] => String
  def hello_world(i, str)
    puts "Hello? #{i} #{st
  end
  
  # Works
  def hello_world_two(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype :hello_world_two, [Integer, String] => String
  
  # Also works (String will be converted to Symbol)
  rtype 'hello_world_three', [Integer, String] => String
  def hello_world_three(i, str)
    puts "Hello? #{i} #{str}"
  end

  # Doesn't work. annotation mode works for following (next) method
  def hello_world_four(i, str)
    puts "Hello? #{i} #{str}"
  end
  rtype [Integer, String] => String
end
```

#### In the outside of module (root)
In the outside of module, annotation mode doesn't work. You must specify method name.

```ruby
rtype :say, [String] => Any
def say(message)
  puts message
end

Test.new.say "Hello" # Hello

rtype [String] => Any
# (ArgumentError) Annotation mode not working in the outside of module
```

#### Class method
Annotation mode works for both instance method and class method

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

if you specify method name, however, you must use `rtype_self` instead of `rtype`

```ruby
require 'rtype'

class Example
  rtype_self :say_ya, [:to_i] => Any
  def self.say_ya(i)
    puts "say" + " ya"*i.to_i
  end
end

Example::say_ya(3) #say ya ya ya
```

#### Type information
This is just 'information'

Any change of this doesn't affect type checking

```ruby
require 'rtype'

class Example
  rtype [:to_i] => Any
  def test(i)
  end
end

Example.new.method(:test).type_info
# => [:to_i] => Any
Example.new.method(:test).argument_type
# => [:to_i]
Example.new.method(:test).return_type
# => Any
```

#### Special Behaviors
  - `TypedArray` : Ensures value is an array with the type (type signature)
    - `Array::of(type)` (recommended)
    - or `Rtype::Behavior::TypedArray[type]`
    - Example: [TypedArray](#typed-array)
  
  - `Num, Int, Flo` : Numeric check
    - `Num/Int/Flo >/>=/</<=/== x`
    - e.g. `Num >= 2` means value must be a `Numeric` and >= 2
    - e.g. `Int >= 2` means value must be a `Integer` and >= 2
    - e.g. `Flo >= 2` means value must be a `Float` and >= 2
  
  - `And` : Ensures value is valid for all given types
    - `Rtype::and(*types)`, `Rtype::Behavior::And[*types]`
    - or `Array#comb`, `Object#and(*others)`
    
  - `Xor` : Ensures value is valid for only one of given types
    - `Rtype::xor(*types)`, `Rtype::Behavior::Xor[*types]`
    - or `Object#xor(*others)`

  - `Not` : Ensures value is not valid for all given types
    - `Rtype::not(*types)`, `Rtype::Behavior::Not[*types]`
    - or `Object#not`

  - `Nilable` : Value can be nil
    - `Rtype::nilable(type)`, `Rtype::Behavior::Nilable[type]`
    - or `Object#nilable`, `Object#or_nil`

  - You can create custom behaviors by extending `Rtype::Behavior::Base`

## Documentation
[RubyDoc.info](http://www.rubydoc.info/gems/rtype)

## Benchmarks
Result of `rake benchmark` ([source](https://github.com/sputnikgugja/rtype/tree/master/benchmark/benchmark.rb))

### MRI
```
Rtype with C native extension
Ruby version: 2.1.7
Ruby engine: ruby
Ruby description: ruby 2.1.7p400 (2015-08-18 revision 51632) [x64-mingw32]
Rtype version: 0.3.0
Rubype version: 0.3.1
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure    85.328k i/100ms
               rtype    25.665k i/100ms
              rubype    21.414k i/100ms
                 sig     8.921k i/100ms
           contracts     4.638k i/100ms
           typecheck     1.110k i/100ms
Calculating -------------------------------------
                pure      3.282M (± 2.7%) i/s -     16.468M
               rtype    339.065k (± 2.6%) i/s -      1.720M
              rubype    266.893k (± 5.9%) i/s -      1.349M
                 sig     99.952k (± 2.1%) i/s -    499.576k
           contracts     49.693k (± 1.5%) i/s -    250.452k
           typecheck     11.356k (± 1.6%) i/s -     57.720k

Comparison:
                pure:  3282431.9 i/s
               rtype:   339064.9 i/s - 9.68x slower
              rubype:   266892.9 i/s - 12.30x slower
                 sig:    99952.2 i/s - 32.84x slower
           contracts:    49693.0 i/s - 66.05x slower
           typecheck:    11355.9 i/s - 289.05x slower
```

### JRuby
Without Rubype that doesn't support JRuby

```
Rtype with Java extension
Ruby version: 2.2.3
Ruby engine: jruby
Ruby description: jruby 9.0.5.0 (2.2.3) 2016-01-26 7bee00d Java HotSpot(TM) 64-Bit Server VM 25.60-b23 on 1.8.0_60-b27 +jit [Windows 10-amd64]
Rtype version: 0.3.0
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure     9.994k i/100ms
               rtype     6.181k i/100ms
                 sig     4.041k i/100ms
           contracts   951.000  i/100ms
           typecheck   970.000  i/100ms
Calculating -------------------------------------
                pure      7.128M (?±35.6%) i/s -     30.831M
               rtype    121.556k (?± 6.2%) i/s -    605.738k
                 sig     72.187k (?± 6.4%) i/s -    359.649k
           contracts     24.984k (?± 3.9%) i/s -    125.532k
           typecheck     12.041k (?± 9.5%) i/s -     60.140k

Comparison:
                pure:  7128373.0 i/s
               rtype:   121555.8 i/s - 58.64x slower
                 sig:    72186.8 i/s - 98.75x slower
           contracts:    24984.5 i/s - 285.31x slower
           typecheck:    12041.0 i/s - 592.01x slower
```

## Rubype, Sig
Rtype is influenced by [Rubype](https://github.com/gogotanaka/Rubype) and [Sig](https://github.com/janlelis/sig).

If you don't like Rtype, You can use other library such as Contracts, Rubype, Rtc, Typecheck, Sig.

## Author
Sputnik Gugja (sputnikgugja@gmail.com)

## License
MIT license (@ Sputnik Gugja)

See `LICENSE` file.
