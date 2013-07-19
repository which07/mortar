# This is a monkey patch
#
# we need a method to reset the global configuration of Bundler. If bundler is already loaded,
# in the case that mortar is run itself through bundler, then we need to reset to allow us to properly
# install the bundle in the correct location.
module Bundler
  class << self
    def nuke_configuration
      [:@bundle_path, :@settings].each { |var|
        self.instance_variable_set var, nil
      }
    end
  end
end
