require 'mortar/helpers'
require 'mortar/version'

module Mortar
  module Updater
    def self.get_newest_version
      begin
        require "excon"
        gem_data = Mortar::Helpers.json_decode(Excon.get('http://rubygems.org/api/v1/gems/mortar.json').body)
        gem_data.default = "0.0.0"
        gem_data['version']
      rescue Exception => e
        '0.0.0'
      end
    end

    def self.compare_versions(first_version, second_version)
      first_version.split('.').map {|part| Integer(part) rescue part} <=> second_version.split('.').map {|part| Integer(part) rescue part}
    end

    def self.update_check
      local_version = Mortar::VERSION
      newest_version = self.get_newest_version

      if compare_versions(newest_version, local_version) > 0
        Mortar::Helpers.warning("There is a new Mortar client available.  Please run 'gem install mortar' to install the latest version.\n\n")
      end
    end
  end
end