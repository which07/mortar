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

# create a reusable dataset.
#
class Mortar::Command::Datasets < Mortar::Command::Base

  #datasets:sample [INPUT_URL] [PERCENT_TO_RETURN] [DATASET_NAME]
  #
  #Create a resuable dataset [DATASET_NAME] made up of [PERCENT_TO_RETURN]
  #percent of rows from the input file(s) at [INPUT_URL].
  #
  # Examples:
  #
  # $ mortar datasets:sample s3n://tbmmsd/*.tsv.* 0.001 samll_song_sample
  #
  # TBD
  def sample
    input_url = shift_argument
    sample_percent = shift_argument
    dataset_name = shift_argument
    unless input_url && sample_percent && dataset_name
      error("Usage: mortar datasets:sample INPUT_URL PERCENT_TO_RETURN DATASET_NAME\nMust specifiy INPUT_URL, PERCENT_TO_RETURN, and DATASET_NAME.")
    end
    validate_arguments!
    validate_git_based_project!

    dataset_id = nil
    action("Requesting dataset creation") do
      dataset_id = api.post_dataset_sample(project.name, dataset_name, input_url, sample_percent).body['dataset_id']
    end

    poll_for_dataset_results(dataset_id)
  end

  #datasets:limit [INPUT_URL] [NUM_ROWS] [DATASET_NAME]
  #
  #Create a resuable dataset [DATASET_NAME] made up of [NUM_ROWS]
  #number of rows from the input file(s) at [INPUT_URL].
  #
  # Examples:
  #
  # $ mortar datasets:limit s3n://tbmmsd/*.tsv.* 100 samll_song_sample
  #
  # TBD
  def limit
    input_url = shift_argument
    num_rows = shift_argument
    dataset_name = shift_argument
    unless input_url && num_rows && dataset_name
      error("Usage: mortar datasets:limit INPUT_URL NUM_ROWS DATASET_NAME\nMust specifiy INPUT_URL, NUM_ROWS, and DATASET_NAME.")
    end
    validate_arguments!
    validate_git_based_project!

    dataset_id = nil
    action("Requesting dataset creation") do
      dataset_id = api.post_dataset_limit(project.name, dataset_name, input_url, num_rows).body['dataset_id']
    end

    poll_for_dataset_results(dataset_id)
  end



  private

  def poll_for_dataset_results(dataset_id)
    dataset_result = nil
    display
    ticking(polling_interval) do |ticks|
      dataset_result = api.get_dataset(dataset_id).body
      is_finished =
        Mortar::API::Datasets::STATUSES_COMPLETE.include?(dataset_result["status_code"])

      redisplay("Status: %s %s" % [
        dataset_result['status_description'] + (is_finished ? "" : "..."),
        is_finished ? " " : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
        break
      end
    end

    case dataset_result['status_code']
    when Mortar::API::Datasets::STATUS_FAILED
      error_message = "TODO: Write error message"
      error(error_message)
    when Mortar::API::Datasets::STATUS_CREATED
      dataset_result['sample_s3_urls'].each do |u|
        download_to_file(u['url'], "datasets/#{dataset_result['name']}/#{u['name']}")
        display
      end
    end
  end

end
