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

# create a reusable fixture.
#
class Mortar::Command::Fixtures < Mortar::Command::Base

  WARNING_NUM_ROWS = 50

=begin
  #fixtures:sample [INPUT_URL] [PERCENT_TO_RETURN] [FIXTURE_NAME]
  #
  #Create a reusable fixture [FIXTURE_NAME] made up of [PERCENT_TO_RETURN]
  #percent of rows from the input file(s) at [INPUT_URL].
  #
  # Examples:
  #
  # $ mortar fixtures:sample s3n://tbmmsd/*.tsv.* 0.001 samll_song_sample
  #
  # TBD
  def sample
    input_url = shift_argument
    sample_percent = shift_argument
    fixture_name = shift_argument
    unless input_url && sample_percent && fixture_name
      error("Usage: mortar fixtures:sample INPUT_URL PERCENT_TO_RETURN FIXTURE_NAME\nMust specifiy INPUT_URL, PERCENT_TO_RETURN, and FIXTURE_NAME.")
    end
    if does_fixture_exist(fixture_name)
      error("Fixture #{fixture_name} already exists.")
    end
    validate_arguments!
    validate_git_based_project!

    fixture_id = nil
    action("Requesting fixture creation") do
      fixture_id = api.post_fixture_sample(project.name, fixture_name, input_url, sample_percent).body['fixture_id']
    end

    poll_for_fixture_results(fixture_id)
  end
=end

  #fixtures:head [INPUT_URL] [NUM_ROWS] [FIXTURE_NAME]
  #
  #Create a reusable fixture [FIXTURE_NAME] made up of [NUM_ROWS]
  #number of rows from the head of the input file(s) at [INPUT_URL].
  #
  # Examples:
  #
  # $ mortar fixtures:head s3n://tbmmsd/*.tsv.* 100 samll_song_sample
  #
  # TBD
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
      error_message = "TODO: Write error message"
      error(error_message)
    when Mortar::API::Fixtures::STATUS_CREATED
      fixture_result['sample_s3_urls'].each do |u|
        download_to_file(u['url'], "fixtures/#{fixture_result['name']}/#{u['name']}")
        display
      end
    end
  end

end
