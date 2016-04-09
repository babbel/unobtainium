# Rubocop
require 'rubocop/rake_task'
RuboCop::RakeTask.new

# Rspec
require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)

# Combined test task
desc "Test the code"
task :test do
  Rake::Task[:rubocop].invoke
  Rake::Task[:spec].invoke
end

# Default is the test task
task default: :test
