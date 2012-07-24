require "mortar"
require "mortar/helpers"


class Mortar::Auth
  class << self
    include Mortar::Helpers

    def default_host
      "mortar.com"
    end

    def host
      ENV['MORTAR_HOST'] || default_host
    end
  end
end
