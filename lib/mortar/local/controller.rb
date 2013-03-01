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

require "mortar/local"
require "mortar/helpers"
require "mortar/local/pig"
require "mortar/local/java"
require "mortar/local/python"


class Mortar::Local::Controller
  class << self
    include Mortar::Helpers

    # Main entry point to perform installation and configuration necessary
    # to run pig on the users local machine
    def install_and_configure
      java = Mortar::Local::Java.new()
      unless java.check_install
        error("Please install java and/or set JAVA_HOME before continueing")
      end

      pig = Mortar::Local::Pig.new()
      pig.install()

      py = Mortar::Local::Python.new()
      unless py.check_or_install
        error("Could not find a suitable python installation with virtualenv installed")
      end

      unless py.setup_project_python_environment
        msg = "\nUnable to setup a python environment with your dependencies, "
        msg += "see #{py.pip_error_log_path} for more details"
        error(msg)
      end
    end

    def verify_aws_keys()
      if (!(ENV['AWS_ACCESS_KEY'] and ENV['AWS_SECRET_KEY'])) then
        return false
      else
        return true
      end
    end

    # Main entry point for user running a pig script
    def run(pig_script, pig_parameters)
      unless verify_aws_keys()
        msg = "Please specify your aws access key via enviroment variable AWS_ACCESS_KEY\n"
        msg += "and your aws secret key via enviroment variable AWS_SECRET_KEY"
        error(msg)
      end
      install_and_configure
      pig = Mortar::Local::Pig.new()
      pig.run_script(pig_script, pig_parameters)
    end

  end
end
