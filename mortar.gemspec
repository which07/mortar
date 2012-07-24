$:.unshift File.expand_path("../lib", __FILE__)
require "mortar/version"

Gem::Specification.new do |gem|
  gem.name    = "mortar"
  gem.version = Mortar::VERSION

  gem.author      = "Mortar Data"
  gem.email       = "support@mortardata.com"
  gem.homepage    = "http://mortardata.com/"
  gem.summary     = "Client library and CLI to interact with the Mortar service."
  gem.description = "Client library and command-line tool to interact with the Mortar service."
  gem.executables = "mortar"
  gem.platform    = Gem::Platform::RUBY
  gem.required_ruby_version = '>=1.9'
  
  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/)} }
  
  gem.add_dependency "netrc",       "~> 0.7.5"
  gem.add_dependency "rest-client", "~> 1.6.1"
  gem.add_dependency "launchy",     ">= 0.3.2"
  gem.add_dependency "rubyzip"
end
