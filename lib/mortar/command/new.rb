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

require "mortar/command"
require "mortar/command/base"

# create a new mortar project
#
class Mortar::Command::New < Mortar::Command::Base
  # new PROJECTNAME
  #
  # create a mortar project in a new directory with the name PROJECTNAME
  def index
    name = shift_argument
    unless name
      error("Usage: mortar new PROJECTNAME\nMust specify PROJECTNAME")
    end

    Mortar::Command::run("projects:create", [name])
  end
end