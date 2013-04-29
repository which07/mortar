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
require "mortar/local/server"

require 'sinatra/base'
require 'thin'
require "json"
require "listen"

require "eventmachine"

class Mortar::Local::Watcher
  include Mortar::Local::InstallUtil

	def initialize(pig_script)
		@pig_script = pig_script
	end

  def illustrate_cache_root
    "#{local_install_directory_name}/watcher"
  end

	def watch 

    pig = Mortar::Local::Pig.new()
    pig.startup_grunt do |stdin, stdout, stderr|
      EM.run do

        new_commands = EM.spawn do |commands|
          puts "starting illustrate"
          last_line = ""
          readline_nonblock = lambda {
            line = ""
            begin
              ch = nil
              while ch = stdout.read_nonblock(1)
                line += ch
                if ch == "\n"
                  return line
                end
              end
            rescue IO::WaitReadable
              if !!line.match(/grunt>\s?$/)
                last_line = line
                return false
              end
              IO.select([stdout])
              retry
            end
          }
          line = false
          while true do
            if line == false
              if commands.empty?
                break
              else
                next_command = commands.shift
                stdin.puts next_command
              end
            else
              puts line
            end
            line = readline_nonblock.call()
          end

          json_data = last_line.gsub(/grunt>\s?$/, "")

          EM.next_tick do
            puts "Notifying pollers"
            App.settings.connections.each do |func|
              puts "Poller notified"
              func.call(json_data)
            end
            App.settings.connections = []
          end
        end

        listener = Listen.to(File.dirname(@pig_script.path),
            :filter => /#{Regexp.quote(@pig_script.name)}\.pig$/)

        current_aliases = []
        current_lines = []

        change_handler = lambda { |modified, added, removed|
          puts current_aliases
          puts "Calculating illustrate..."
          begin
            lines = @pig_script.code.gsub(/--.*\n?/, "").gsub(/^\s*\n+/, "").gsub(/\s*(rmf|store).*;/mi, "")
            line_array = lines.split(";").map { |e| "#{e};\n" }

            executable_lines = (line_array - current_lines)

            new_aliases = line_array.map { |line| line.scan(/\s*(\S*)\s*=/) }
            (current_aliases - new_aliases).each do |a|
              executable_lines.unshift "#{a[0][0]} = NULL;\n"
            end

            current_aliases = new_aliases
            current_lines = executable_lines
            
            last_alias = lines.scan(/^\s*(\S*)\s*=/)[-1][0]
            executable_lines << "illustrate -skipPruning #{last_alias};\n"

            puts line_array

            EM.next_tick do
              new_commands.notify(executable_lines)
            end

          rescue
          end
        }


        listener.change(&change_handler)
        listener.start(false)

        Thin::Server.start App, '0.0.0.0', 3000
      end     

    end
    
	end

end

