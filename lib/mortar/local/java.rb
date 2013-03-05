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

class Mortar::Local::Java
  include Mortar::Local::InstallUtil

  @command = nil

  def check_install
    jbin = File.join(ENV['JAVA_HOME'], "bin", "java")
    if ENV['JAVA_HOME'] and File.exists?(jbin)
      @command = jbin
      return true
    elsif File.exists?("/usr/libexec/java_home")
      # OSX has a nice little tool for finding this value, assuming
      # that it won't give us a bad value
      java_home = `/usr/libexec/java_home`.to_s.strip
      if java_home != ""
        ENV['JAVA_HOME'] = java_home
        @command = File.join(ENV['JAVA_HOME'], "bin", "java")
        return true
      end
    end
    return false
  end

end
