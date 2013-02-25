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

require "mortar/command/base"
require "mortar/snapshot"

# create a reusable fixture.
#
class Mortar::Command::Fixtures < Mortar::Command::Base
  include Mortar::Snapshot

  # fixtures
  #
  # Show available fixtures
  #
  # Examples:
  #
  # $ mortar fixtures
  #
  def fixtures
  end

  # fixtures:limit PIGSCRIPT ALIAS N
  #
  # Generate a fixture of N records from ALIAS.
  #
  # -n, --name      NAME        # Specify a name for this fixture. default = PIGSCRIPT_ALIAS_LIMIT_N
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  #
  # Example:
  #
  # Take 100 records from alias
  # $ mortar fixtures:limit my_script alias 100
  def limit
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    n = shift_argument
    unless pigscript_name and fixture_alias and n
      error("Usage: mortar fixtures:limit PIGSCRIPT ALIAS N\nMust specify PIGSCRIPT, ALIAS, N")
    end
    validate_arguments!

    pigscript = validate_pigscript!(pigscript_name)
    unless n.to_i > 0
      error("N must be a positive integer")
    end

    fixture_name = options[:name] || ("file:///tmp/fixtures/" + pigscript_name + "__" + fixture_alias + "__limit__" + n)
    git_ref = create_and_push_snapshot_branch(git, project)

    response = action("Requesting fixture creation") do
      api.post_fixture_generate(project.name, pigscript.name, git_ref, 
                                fixture_name, "LIMIT", fixture_alias, n)
    end
  end

  # fixtures:sample PIGSCRIPT ALIAS FRACTION
  #
  # Generate a fixture from a random sample of FRACTION*100% of the records in ALIAS.
  #
  # -n, --name      NAME        # Specify a name for this fixture. default = PIGSCRIPT_ALIAS_SAMPLE_FRACTION
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  #
  # Example:
  #
  # Take 1% of the records from alias
  # $ mortar fixtures:sample my_script alias 0.01
  #
  def sample
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    n = shift_argument
    unless pigscript_name and fixture_alias and n
      error("Usage: mortar fixtures:sample PIGSCRIPT ALIAS N\nMust specify PIGSCRIPT, ALIAS, N")
    end
    validate_arguments!

    pigscript = validate_pigscript!(pigscript_name)
    unless n.to_f > 0.0 and n.to_f < 1.0
      error("N must be a decimal between 0 and 1")
    end

    fixture_name = options[:name] || ("file:///tmp/fixtures/" + pigscript_name + "__" + fixture_alias + "__sample__" + n)
    git_ref = create_and_push_snapshot_branch(git, project)
    
    response = action("Requesting fixture creation") do
      api.post_fixture_generate(project.name, pigscript.name, git_ref, 
                                fixture_name, "SAMPLE", fixture_alias, n)
    end
  end

  # fixtures:filter PIGSCRIPT ALIAS FILTER
  #
  # Generate a fixture from all the records in ALIAS which pass the Pig stament "FILTER ALIAS BY FILTER".
  # The -n/--name parameter is required.
  #
  # -n, --name      NAME        # Specify a name for this fixture.
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  #
  # Example:
  #
  # Take records from alias for which f1 > f2
  # $ mortar fixtures:filter my_script alias "f1 > f2"
  def filter
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    filter = get_remaining_arguments_as_string
    unless pigscript_name and fixture_alias and filter
      error("Usage: mortar fixtures:filter PIGSCRIPT ALIAS FILTER\nMust specify PIGSCRIPT, ALIAS, FILTER")
    end
    validate_arguments!

    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)

    unless options[:name]
      error("Must specify a fixture name with -n/--name")
    end
    git_ref = create_and_push_snapshot_branch(git, project)
    
    response = action("Requesting fixture creation") do
      api.post_fixture_generate(project.name, pigscript.name, git_ref, 
                                options[:name], "LIMIT", fixture_alias, filter, 
                                :parameters => pig_parameters).body
    end
    puts response
  end

=begin
  WARNING_NUM_ROWS = 50

  #fixtures:head [INPUT_URL] [NUM_ROWS] [FIXTURE_NAME]
  #
  #Create a reusable fixture [FIXTURE_NAME] made up of [NUM_ROWS]
  #number of rows from the head of the input file(s) at [INPUT_URL].
  #
  # Examples:
  #
  # $ mortar fixtures:head s3n://tbmmsd/*.tsv.* 100 samll_song_sample
  #
  def head
    input_url = shift_argument
    num_rows = shift_argument
    fixture_name = shift_argument
    unless input_url && num_rows && fixture_name
      error("Usage: mortar fixtures:head INPUT_URL NUM_ROWS FIXTURE_NAME\nMust specifiy INPUT_URL, NUM_ROWS, and FIXTURE_NAME.")
    end
    if does_fixture_exist(fixture_name)
      error("Fixture #{fixture_name} already exists.")
    end
    unless num_rows.to_i < WARNING_NUM_ROWS
      warning("Creating fixtures with more than #{WARNING_NUM_ROWS} rows is not recommended.  Large local fixtures may cause slowness when using Mortar.")
      display
    end
    validate_arguments!
    validate_git_based_project!

    fixture_id = nil
    action("Requesting fixture creation") do
      fixture_id = api.post_fixture_limit(project.name, fixture_name, input_url, num_rows).body['fixture_id']
    end

    poll_for_fixture_results(fixture_id)
  end



  private

  def does_fixture_exist(fixture_name)
    fixture_path = File.join(project.fixtures_path, fixture_name)
    File.exists?(fixture_path)
  end

  def poll_for_fixture_results(fixture_id)
    fixture_result = nil
    display
    ticking(polling_interval) do |ticks|
      fixture_result = api.get_fixture(fixture_id).body
      is_finished =
        Mortar::API::Fixtures::STATUSES_COMPLETE.include?(fixture_result["status_code"])

      redisplay("Status: %s %s" % [
        fixture_result['status_description'] + (is_finished ? "" : "..."),
        is_finished ? "" : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
         break
      end
    end

    case fixture_result['status_code']
    when Mortar::API::Fixtures::STATUS_FAILED
      error_message = "Fixture generation failed with #{fixture_result['error_type'] || 'error'}"
      error_context = get_error_message_context(fixture_result['error_message'] || "")
      error_message += ":\n\n#{fixture_result['error_message']}\n\n#{error_context}"
      error(error_message)
    when Mortar::API::Fixtures::STATUS_CREATED
      fixture_result['sample_s3_urls'].each do |u|
        download_to_file(u['url'], "fixtures/#{fixture_result['name']}/#{u['name']}")
        display
      end
    end
  end
=end

end
