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
require "mortar/local/controller"
require "mortar/command/base"

# run select pig commands on your local machine
#
class Mortar::Command::Local < Mortar::Command::Base
  include Mortar::Fixtures

  # local:configure
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
  # -F, --usefixtures           # Automatically use all fixtures defined for this pigscript
  # -x, --fixture FIXTURE_NAME  # Use a specific fixture (can use this option more than once) 
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
    fixture_argument = load_fixture_argument(project.fixture_mappings_path, script_name,
                                             options[:usefixtures], options[:fixture])

    ctrl = Mortar::Local::Controller.new
    ctrl.run(script, pig_parameters, fixture_argument)
  end

  # local:illustrate [PIGSCRIPT] [ALIAS]
  #
  # Locally illustrate the effects and output of a pigscript.
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


  # local:validate SCRIPT
  #
  # Run a job on your local machine
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  #
  #Examples:
  #
  #    Check the pig syntax of the generate_regression_model_coefficients script locally.
  #        $ mortar local:validate generate_regression_model_coefficients
  def validate
    script_name = shift_argument
    unless script_name
      error("Usage: mortar local:validate SCRIPT\nMust specify SCRIPT.")
    end
    validate_arguments!
    script = validate_script!(script_name)
    ctrl = Mortar::Local::Controller.new
    ctrl.validate(script, pig_parameters)
  end

  # local:fixtures_limit PIGSCRIPT ALIAS FIXTURE_NAME N
  #
  # Generate a fixture of N records from ALIAS.
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  # -F, --overwrite             # If there is an existing fixture with the same name, overwrite it
  #
  # Example:
  #
  # Take 10,000 records from the alias "users"
  # $ mortar local:fixtures_limit my_script users users_10k 10000
  def fixtures_limit
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    fixture_name = shift_argument
    n = shift_argument
    unless pigscript_name and fixture_alias and fixture_name and n
      error("Usage: mortar local:fixtures_limit PIGSCRIPT ALIAS FIXTURE_NAME N\n" +
            "Must specify PIGSCRIPT, ALIAS, FIXTURE_NAME, N")
    end
    validate_arguments!

    pigscript = validate_pigscript!(pigscript_name)
    fixture_overwrite_check(project.fixtures_path, project.fixture_mappings_path, 
                            fixture_name, options[:overwrite])
    unless n.to_i > 0
      error("N must be a positive integer")
    end

    output_uri = project.fixtures_path + "/" + fixture_name
    fixture_argument = store_fixture_argument(:LIMIT, fixture_alias,
                                              n, output_uri)

    ctrl = Mortar::Local::Controller.new
    ctrl.run(pigscript, pig_parameters, fixture_argument)

    add_fixture_mapping(project.fixture_mappings_path,
                        fixture_name, pigscript_name, fixture_alias, output_uri)
    ensure_fixtures_in_gitignore(project.root_path)
  end

  # local:fixtures_sample PIGSCRIPT ALIAS FIXTURE_NAME FRACTION
  #
  # Generate a fixture from a random sample of FRACTION*100% of the records in ALIAS.
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  # -F, --overwrite             # If there is an existing fixture with the same name, overwrite it
  #
  # Example:
  #
  # Take 1% of the records from the alias "users"
  # $ mortar local:fixtures_sample my_script users one_percent_users 0.01
  #
  def fixtures_sample
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    fixture_name = shift_argument
    fraction = shift_argument
    unless pigscript_name and fixture_alias and fixture_name and fraction
      error("Usage: mortar local:fixtures_sample PIGSCRIPT ALIAS FIXTURE_NAME FRACTION\n" +
            "Must specify PIGSCRIPT, ALIAS, FIXTURE_NAME, FRACTION")
    end
    validate_arguments!

    pigscript = validate_pigscript!(pigscript_name)
    fixture_overwrite_check(project.fixtures_path, project.fixture_mappings_path, 
                            fixture_name, options[:overwrite])
    unless fraction.to_f > 0.0 and fraction.to_f < 1.0
      error("FRACTION must be a decimal between 0 and 1")
    end

    output_uri = project.fixtures_path + "/" + fixture_name
    fixture_argument = store_fixture_argument(:SAMPLE, fixture_alias,
                                              fraction, output_uri)

    ctrl = Mortar::Local::Controller.new
    ctrl.run(pigscript, pig_parameters, fixture_argument)
    add_fixture_mapping(project.fixture_mappings_path,
                        fixture_name, pigscript_name, fixture_alias, output_uri)
    ensure_fixtures_in_gitignore(project.root_path)
  end

  # local:fixtures_filter PIGSCRIPT ALIAS FIXTURE_NAME "FILTER_STATEMENT"
  #
  # Generate a fixture from all the records in ALIAS
  # which pass the Pig statement "FILTER ALIAS BY FILTER_STATEMENT".
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  # -F, --overwrite             # If there is an existing fixture with the same name, overwrite it
  #
  # Example:
  #
  # Take records from alias "users" for which field "num_followers" is > 1000
  # $ mortar local:fixtures_filter my_script users popular_users "num_followers > 1000"
  def fixtures_filter
    pigscript_name = shift_argument
    fixture_alias = shift_argument
    fixture_name = shift_argument
    filter_statement = get_remaining_arguments_as_string
    unless pigscript_name and fixture_alias and fixture_name and filter_statement
      error("Usage: mortar local:fixtures_filter PIGSCRIPT ALIAS FIXTURE_NAME \"FILTER_STATEMENT\"\n" +
            "Must specify PIGSCRIPT, ALIAS, FIXTURE_NAME, FILTER_STATEMENT")
    end
    validate_arguments!
    
    pigscript = validate_pigscript!(pigscript_name)
    fixture_overwrite_check(project.fixtures_path, project.fixture_mappings_path, 
                            fixture_name, options[:overwrite])

    output_uri = project.fixtures_path + "/" + fixture_name
    fixture_argument = store_fixture_argument(:FILTER, fixture_alias,
                                              filter_statement, output_uri)

    ctrl = Mortar::Local::Controller.new
    ctrl.run(pigscript, pig_parameters, fixture_argument)
    add_fixture_mapping(project.fixture_mappings_path,
                        fixture_name, pigscript_name, fixture_alias, output_uri)
    ensure_fixtures_in_gitignore(project.root_path)
  end

end
