require "mortar/command/base"
require "mortar/version"

# display version
#
class Mortar::Command::Version < Mortar::Command::Base

  # version
  #
  # show mortar client version
  #
  #Example:
  #
  # $ mortar version
  # mortar/1.2.3 (x86_64-darwin11.4.2) ruby/1.9.3
  #
  def index
    validate_arguments!

    display(Mortar::USER_AGENT)
  end

end
