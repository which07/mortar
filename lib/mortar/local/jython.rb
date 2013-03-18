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

require "mortar/local/installutil"

class Mortar::Local::Jython
  include Mortar::Local::InstallUtil

  JYTHON_VERSION = '2.5.2'
  JYTHON_JAR_NAME = 'jython_installer-' + JYTHON_VERSION + '.jar'
  JYTHON_JAR_DIR = "http://s3.amazonaws.com/hawk-dev-software-mirror/jython/jython-2.5.2/"

  def install_if_not_present
    unless File.exists?(local_install_directory + '/jython/jython.jar')
      unless File.exists?(local_install_directory + '/' + JYTHON_JAR_NAME)
        display("Downloading jython...")
        download_file(JYTHON_JAR_DIR + JYTHON_JAR_NAME, local_install_directory)
      end

      action("Installing jython") do
        `echo $JAVA_HOME/bin/java`
        `$JAVA_HOME/bin/java -jar #{local_install_directory + '/' + JYTHON_JAR_NAME} -s -d #{local_install_directory}/jython`

        FileUtils.mkdir_p jython_cache_directory
        FileUtils.chmod_R 0777, jython_cache_directory
      end
    end
  end
end