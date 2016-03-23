require 'rubygems'
require 'rake'
require 'rake/testtask'

desc 'Default: run all tests.'
task :default => :test

desc "Test has_messages."
Rake::TestTask.new(:test) do |t|
  t.libs << 'lib'
  t.test_files = Dir['test/**/*_test.rb']
  t.verbose = true
end
