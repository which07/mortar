#
# Copyright 2013 Mortar Data Inc.
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
require "mortar/helpers"
require "mortar/local/pig"
require "listen"

class Mortar::Local::Watcher
	def initialize(pig_script)
		@pig_script = pig_script
	end

	def watch 
    pig = Mortar::Local::Pig.new()

    change_handler = lambda { |modified, added, removed|
      display("File change deteched, recalculating illustrate...")
      pig.illustrate_alias(@pig_script, nil, true, []) do |output_path|
        puts output_path
      end
    }

    display "Wathching #{@pig_script.name}..."

    Listen.to(File.dirname(@pig_script.path),
                :filter => /#{Regexp.quote(@pig_script.name)}\.pig$/,
                &change_handler) 
	end
end