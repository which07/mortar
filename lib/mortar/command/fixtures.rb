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

require "mortar/fixtures"
require "mortar/command/base"

class Mortar::Command::Fixtures < Mortar::Command::Base
  include Mortar::Fixtures

  # fixtures
  #
  # Show available fixtures
  #
  # Examples:
  #
  # $ mortar fixtures
  #
  def index
    validate_arguments!
    mappings = fixture_mappings(project.fixture_mappings_path)

    if mappings.size > 0
      display("Name, Pigscript, Alias, URI")
      mappings.each do |m|
        display("#{m["name"]}\t#{m["pigscript"]}\t#{m["alias"]}\t#{m["uri"]}")
      end
    else
      display("You have no fixtures.")
    end
  end

  # fixtures:delete FIXTURE_NAME
  #
  # Delete a fixture
  #
  # Examples:
  #
  # $ mortar fixtures:delete my_fixture
  def delete
    fixture_name = shift_argument
    validate_arguments!
    delete_fixture(project.fixtures_path, project.fixture_mappings_path, fixture_name)
  end
end