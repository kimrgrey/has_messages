$LOAD_PATH.unshift File.expand_path('../lib', __FILE__)
require 'has_messages/version'

Gem::Specification.new do |s|
  s.name              = "has_messages"
  s.version           = HasMessages::VERSION
  s.authors           = ["Aaron Pfeifer"]
  s.email             = "aaron@pluginaweek.org"
  s.homepage          = "http://www.pluginaweek.org"
  s.description       = "Demonstrates a reference implementation for sending messages between users in ActiveRecord"
  s.summary           = "User-to-user messaging in ActiveRecord"
  s.require_paths     = ["lib"]
  s.files             = `git ls-files`.split("\n")
  s.test_files        = `git ls-files -- test/*`.split("\n")
  s.rdoc_options      = %w(--line-numbers --inline-source --title has_messages --main README.rdoc)
  s.extra_rdoc_files  = %w(README.rdoc CHANGELOG.rdoc LICENSE)

  s.add_runtime_dependency "state_machines-activerecord"
  s.add_runtime_dependency "activerecord", ">= 4.0.0"

  s.add_development_dependency "rake"
  s.add_development_dependency "minitest", "~> 5.8.4"
  s.add_development_dependency "database_cleaner"
  s.add_development_dependency "sqlite3"
end
