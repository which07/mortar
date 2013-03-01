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

class Mortar::Command::Local < Mortar::Command::Base


  # configure
  #
  # Install dependencies for running this pig project locally, other
  # commands will also perform this step automatically.
  #
  def configure
    Mortar::Local::Controller.install_and_configure
  end

  # local:run PIGSCRIPT
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
    pigscript_name = shift_argument
    unless pigscript_name
      error("Usage: mortar local:run PIGSCRIPT\nMust specify PIGSCRIPT.")
    end
    validate_arguments!

    pigscript = validate_pigscript!(pigscript_name)

    Mortar::Local::Controller.run(pigscript, pig_parameters)

  end

end
