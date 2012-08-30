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
    class MacroGenerator < Base

      def generate_macro(macro_name, project, options)
        set_script_binding(macro_name, options)
        generate_file "macro.pig", "macros/#{macro_name}.pig", :recursive => true
      end
      
      protected

        def set_script_binding(macro_name, options)
          options = options
          macro_name = macro_name
          @script_binding = binding
        end

    end
  end
end