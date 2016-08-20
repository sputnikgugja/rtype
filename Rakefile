require "rspec/core/rake_task"

# Default pattern is 'spec/**{,/*/**}/*_spec.rb'
RSpec::Core::RakeTask.new(:spec)

task :default => [:spec]

# Benchmark
desc "Compare with pure ruby and other gems"
task :benchmark do
	ruby "benchmark/benchmark.rb"
end
