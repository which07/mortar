#
# Copyright 2012 Mortar Data Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# Portions of this code from heroku (https://github.com/heroku/heroku/) Copyright Heroku 2008 - 2012,
# used under an MIT license (https://github.com/heroku/heroku/blob/master/LICENSE).
#

require "mortar/command/base"

# authentication (login, logout)
#
class Mortar::Command::Auth < Mortar::Command::Base

  # auth:login
  #
  # log in with your mortar credentials
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
  def logout
    validate_arguments!

    Mortar::Auth.logout
    display "Local credentials cleared."
  end

  alias_command "logout", "auth:logout"

  # auth:key
  #
  # display your api key
  #
  def key
    validate_arguments!
  
    display Mortar::Auth.password
  end
   
  # auth:whoami
  #
  # display your mortar email address
  #
  def whoami
    validate_arguments!

    if Mortar::Auth.has_credentials
      display Mortar::Auth.user
    end
  end

end

