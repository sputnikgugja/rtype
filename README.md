# Rtype: ruby with type
You can do the type checking in Ruby with this gem!

```ruby
require 'rtype'

rtype :sum, [:to_i, Numeric] => Numeric
def sum(a, b)
  a.to_i + b
end

sum(123, "asd")
# (Rtype::ArgumentTypeError) for 2nd argument:
# Expected "asd" to be a Numeric

class Test
  rtype_self :invert, {state: Boolean} => Boolean
  def self.invert(state:)
    !state
  end
end

Test::invert(state: 0)
# (Rtype::ArgumentTypeError) for 'state' argument:
# Expected 0 to be a Boolean
```

## Requirements
- Ruby >= 2.0

## Features
- Very simple
- Provide type checking for argument and return
- Support type checking for [keyword argument](#keyword-argument)
- [Type checking for array elements](#array)
- [Duck typing](#duck-typing)
- Custom type behavior

## Installation
Run `gem install rtype` or add `gem 'rtype'` to your `Gemfile`

And add to your `.rb` source file:
```ruby
require 'rtype'
```

## Usage

### Supported Type Behaviors
- `Module`
  - Value must be an instance of this module/class or one of it's superclasses
  - `Any` : An alias for `BasicObject` (means Any Object)
  - `Boolean` : `true` or `false`
- `Symbol`
  - Value must have(respond to) a method with this name
- `Regexp`
  - Value must match this regexp pattern
- `Range`
  - Value must be included in this range
- `Array` (tuple)
  - Value must be an array
  - Each of value's elements must be valid
  - Example: [Array](#array)
  - This can be used as a tuple
- `Proc`
  - Value must return a truthy value for this proc
- `true`
  - Value must be **truthy**
- `false`
  - Value must be **falsy**
- `nil`
  - Only available for **return type**. void return type in other languages
- Special Behaviors
  - `Rtype::and(*types)` : Ensure value is valid for all the types
    - It also can be used as `Rtype::Behavior::And[*types]` or `include Rtype::Behavior; And[...]`
  - `Rtype::or(*types)` : Ensure value is valid for at least one of the types
    - It also can be used as `Rtype::Behavior::Or[*types]` or `include Rtype::Behavior; Or[...]`
  - `Rtype::xor(*types)` : Ensure value is valid for only one of the types
    - It also can be used as `Rtype::Behavior::Xor[*types]` or `include Rtype::Behavior; Xor[...]`
  - `Rtype::not(*types)` : Ensure value is not valid for all the types
    - It also can be used as `Rtype::Behavior::Not[*types]` or `include Rtype::Behavior; Not[...]`
  - `Rtype::nilable(type)` : Ensure value can be nil
    - It also can be used as `Rtype::Behavior::Nilable[type]` or `include Rtype::Behavior; Nilable[...]`
  - You can create custom behavior by extending `Rtype::Behavior::Base`

### Examples

#### Basic
```ruby
require 'rtype'

class Example
  rtype :test, [Integer] => nil
  def test(i)
  end
  
  rtype :any_type_arg, [Any] => nil
  def any_type_arg(arg)
  end
  
  rtype :return_type_test, [] => Integer
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
  rtype :say_your_name, {name: String} => Any
  def say_your_name(name:)
    puts "My name is #{name}"
  end
  
  # Mixing positional arguments and keyword arguments
  rtype :name_and_age, [String, {age: Integer}] => Any
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
  rtype :says, [:to_i] => Any
  def says(i)
    puts "duck:" + " quack"*i.to_i
  end
end

Duck.new.says("2") # duck: quack quack
```

#### Array
This can be used as a tuple.

```ruby
rtype :func, [[Numeric, Numeric]] => Any
def func(arr)
  puts "Your location is (#{arr[0]}, #{arr[1]}). I will look for you. I will find you"
end

func [1, "str"]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1, "str"] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected "str" to be a Numeric

func [1, 2, 3]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1, 2, 3] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected 2 to be a Numeric

func [1]
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected [1] to be an array with 2 elements:
# - [0] index : Expected 1 to be a Numeric
# - [1] index : Expected nil to be a Numeric

func [1, 2] # Your location is (1, 2). I will look for you. I will find you
```

#### Combined type
```ruby
### TEST 1 ###
require 'rtype'

class Example
  rtype :and_test, [Rtype::and(String, :func)] => Any
  def and_test(arg)
  end
end

Example.new.and_test("A string")
# (Rtype::ArgumentTypeError) for 1st argument:
# Expected "A string" to be a String
# AND Expected "A string" to respond to :func
```
```ruby
### TEST 2 ###
# ... require rtype and define Example the same as above ...

class String
  def func; end
end

Example.new.and_test("A string") # Works!
```

#### Combined duck type
Application of duck typing and combined type

```ruby
require 'rtype'

module Game
  ENEMY = [
    :name,
    :level
  ]
  
  class Player < Entity
    include Rtype::Behavior

    rtype :attack, [And[*ENEMY]] => Any
    def attacks(enemy)
      "Player attacks '#{enemy.name}' (level #{enemy.level})!"
    end
  end
  
  class Slime < Entity
    def name
      "Powerful Slime"
    end
    
    def level
      123
    end
  end
end

Game::Player.new.attacks Game::Slime.new
# Player attacks 'Powerful Slime' (level 123)!
```

#### Position of `rtype` && (symbol || string)
```ruby
require 'rtype'

class Example
  # Works. Recommended
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
end
```

#### Outside of module (root)
Yes, it works

```ruby
rtype :say, [String] => Any
def say(message)
  puts message
end

say "Hello" # Hello
```

#### Static method
Use `rtype_self`

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

#### Check type information
This is just the 'information'

Any change of this doesn't affect type checking

```ruby
require 'rtype'

class Example
  rtype :test, [:to_i] => Any
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

## Benchmarks
Result of `rake benchmark` ([source](https://github.com/sputnikgugja/rtype/tree/master/benchmark/benchmark.rb))

The benchmark doesn't include `Rubype` gem because I can't install Rubype on my environment.

### MRI
```
Ruby version: 2.1.7
Ruby engine: ruby
Ruby description: ruby 2.1.7p400 (2015-08-18 revision 51632) [x64-mingw32]
Rtype version: 0.0.1
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure    84.672k i/100ms
               rtype    10.221k i/100ms
                 sig     8.271k i/100ms
           contracts     4.604k i/100ms
           typecheck     1.102k i/100ms
Calculating -------------------------------------
                pure      3.438M (±33.5%) i/s -     15.580M
               rtype    115.274k (± 9.2%) i/s -    572.376k
                 sig    100.204k (± 8.0%) i/s -    504.531k
           contracts     49.026k (± 9.6%) i/s -    244.012k
           typecheck     11.108k (± 7.4%) i/s -     56.202k

Comparison:
                pure:  3437842.1 i/s
               rtype:   115274.1 i/s - 29.82x slower
                 sig:   100203.7 i/s - 34.31x slower
           contracts:    49025.8 i/s - 70.12x slower
           typecheck:    11107.6 i/s - 309.50x slower
```

### JRuby
```
Ruby version: 2.2.3
Ruby engine: jruby
Ruby description: jruby 9.0.5.0 (2.2.3) 2016-01-26 7bee00d Java HotSpot(TM) 64-Bit Server VM 25.60-b23 on 1.8.0_60-b27 +jit [Windows 10-amd64]
Rtype version: 0.0.1
Sig version: 1.0.1
Contracts version: 0.13.0
Typecheck version: 0.1.2
Warming up --------------------------------------
                pure    17.077k i/100ms
               rtype     2.774k i/100ms
                 sig     3.747k i/100ms
           contracts   907.000  i/100ms
           typecheck   937.000  i/100ms
Calculating -------------------------------------
                pure      5.186M (±50.8%) i/s -     15.933M
               rtype     69.206k (±15.3%) i/s -    341.202k
                 sig     64.460k (±16.4%) i/s -    314.748k
           contracts     24.372k (±13.2%) i/s -    119.724k
           typecheck     11.670k (±12.8%) i/s -     58.094k

Comparison:
                pure:  5185896.5 i/s
               rtype:    69206.2 i/s - 74.93x slower
                 sig:    64460.2 i/s - 80.45x slower
           contracts:    24371.7 i/s - 212.78x slower
           typecheck:    11670.0 i/s - 444.38x slower
```

## Rubype, Sig
Rtype is influenced by [Rubype](https://github.com/gogotanaka/Rubype) and [Sig](https://github.com/janlelis/sig).

If you don't like Rtype, You can use other type checking gem such as Contracts, Rubype, Rtc, Typecheck, Sig.

## Author
Sputnik Gugja (sputnikgugja@gmail.com)

## License
MIT license (@ Sputnik Gugja)

See `LICENSE` file.