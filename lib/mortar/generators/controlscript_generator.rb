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

require "mortar/generators/generator_base"
module Mortar
  module Generators
    class ControlscriptGenerator < Base

      def generate_controlscript(script_name, options)
        set_script_binding(script_name, options)

        generate_file "controlscript.py", "controlscripts/#{script_name}.py", :recursive => true
      end

      protected

        def set_script_binding(script_name, options)
          options = options
          script_name = script_name
          @script_binding = binding
        end
    end
  end
end