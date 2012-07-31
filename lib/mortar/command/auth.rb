require "mortar/command/base"

# authentication (login, logout)
#
class Mortar::Command::Auth < Mortar::Command::Base

  # auth:login
  #
  # log in with your mortar credentials
  #
  #Example:
  #
  # $ mortar auth:login
  # Enter your Mortar credentials:
  # Email: email@example.com
  # Password (typing will be hidden):
  # Authentication successful.
  #
  def login
    validate_arguments!

    Mortar::Auth.login
    display "Authentication successful."
  end

  alias_command "login", "auth:login"

  # auth:logout
  #
  # clear local authentication credentials
  #
  #Example:
  #
  # $ mortar auth:logout
  # Local credentials cleared.
  #
  def logout
    validate_arguments!

    Mortar::Auth.logout
    display "Local credentials cleared."
  end

  alias_command "logout", "auth:logout"

  # auth:whoami
  #
  # display your mortar email address
  #
  #Example:
  #
  # $ mortar auth:whoami
  # email@example.com
  #
  def whoami
    validate_arguments!

    display Mortar::Auth.user
  end

end

