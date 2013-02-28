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

require "mortar"
require "mortar/local/pig"
require "mortar/local/java"
require "mortar/local/python"


module Mortar
  module Local

    # Main entry point to perform installation and configuration necessary
    # to run pig on the users local machine
    def Local.install_and_configure
      java = Mortar::Local::Java.new()
      unless java.check_install
        error("Please install java and/or set JAVA_HOME before continueing")
      end

      pig = Mortar::Local::Pig.new()
      pig.install()

      py = Mortar::Local::Python.new()
      unless py.check_or_install
        # todo: how do we communicate that virtualenv isn't installed?
        error("No suitable python installation found")
      end

      unless py.setup_project_python_environment
        error("Unable to setup a python environment with your dependencies")
      end
    end

  end
end

