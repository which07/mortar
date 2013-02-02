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
  gem.required_ruby_version = '>=1.8.7'
  
  gem.files = %x{ git ls-files }.split("\n").select { |d| d =~ %r{^(License|README|bin/|data/|ext/|lib/|spec/|test/)} }
  
  gem.add_runtime_dependency  "mortar-api-ruby", "~> 0.5.1"
  gem.add_runtime_dependency  "netrc",           "~> 0.7"
  gem.add_runtime_dependency  "launchy",         "~> 2.1"

  gem.add_development_dependency "excon", '~> 0.15'
  gem.add_development_dependency "fakefs"
  gem.add_development_dependency "gem-release"
  gem.add_development_dependency "rake"
  gem.add_development_dependency "rr"
  gem.add_development_dependency "rspec"

end
