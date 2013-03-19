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

require "mortar/local/controller"
require "mortar/command/base"

# run select pig commands on your local machine
#
class Mortar::Command::Local < Mortar::Command::Base


  # configure
  #
  # Install dependencies for running this pig project locally, other
  # commands will also perform this step automatically.
  #
  def configure
    ctrl = Mortar::Local::Controller.new
    ctrl.install_and_configure
  end

  # local:run SCRIPT
  #
  # Run a job on your local machine
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  #
  #Examples:
  #
  #    Run the generate_regression_model_coefficients script locally.
  #        $ mortar local:run generate_regression_model_coefficients
  def run
    script_name = shift_argument
    unless script_name
      error("Usage: mortar local:run SCRIPT\nMust specify SCRIPT.")
    end
    validate_arguments!
    script = validate_script!(script_name)
    ctrl = Mortar::Local::Controller.new
    ctrl.run(script, pig_parameters)
  end

  # illustrate [PIGSCRIPT] [ALIAS]
  #
  # Locallay illustrate the effects and output of a pigscript.
  #
  # -s, --skippruning           # Don't try to reduce the illustrate results to the smallest size possible.
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  # --no_browser                # Don't open the illustrate results automatically in the browser.
  #
  # Examples:
  #
  #     Illustrate the songs_sample relation in the generate_regression_model_coefficients script.
  #         $ mortar illustrate generate_regression_model_coefficients songs_sample
  def illustrate
    pigscript_name = shift_argument
    alias_name = shift_argument
    skip_pruning = options[:skippruning] ||= false

    unless pigscript_name && alias_name
      error("Usage: mortar local:illustrate PIGSCRIPT ALIAS\nMust specify PIGSCRIPT and ALIAS.")
    end

    validate_arguments!
    pigscript = validate_pigscript!(pigscript_name)

    ctrl = Mortar::Local::Controller.new
    ctrl.illustrate(pigscript, alias_name, pig_parameters, skip_pruning)
  end


end
