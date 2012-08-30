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
    class PigscriptGenerator < Base

      def generate_pigscript(script_name, project, options)
        set_script_binding(script_name, options)


        generate_file "pigscript.pig", "pigscripts/#{script_name}.pig", :recursive => true
        copy_file "python_udf.py", "udfs/python/#{script_name}.py", :recursive => true if not options[:skip_udf]
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