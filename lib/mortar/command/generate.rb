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

require "mortar/generators/project_generator"
require "mortar/generators/udf_generator"
require "mortar/generators/pigscript_generator"
require "mortar/generators/macro_generator"
require "mortar/command/base"

# generate mortar code (project, pigscript, python_udf, macro)
#
class Mortar::Command::Generate < Mortar::Command::Base

  # generate:project [PROJECTNAME]
  #
  # Generate the files and directory structure necessary for a Mortar project.
  # 
  def _project
    project_name = shift_argument
    unless project_name
      error("Usage: mortar new PROJECTNAME\nMust specify PROJECTNAME.")
    end
    pigscript_name = project_name
    app_generator = Mortar::Generators::ProjectGenerator.new
    app_generator.generate_project(project_name, options)
  end
  alias_command "new", "generate:_project"
  alias_command "generate:project", "generate:_project"


  # generate:python_udf [UDFNAME]
  #
  # Generate a new python user defined function
  # 
  def python_udf
    udf_name = shift_argument
    unless udf_name
      error("Usage: mortar generate:python_udf UDFNAME\nMust specify UDFNAME.")
    end
    udf_generator = Mortar::Generators::UDFGenerator.new
    udf_generator.generate_python_udf(udf_name, project, options)
  end

  # generate:pigscript [SCRIPTNAME]
  #
  # Generate new pig script.
  #
  # --skip-udf # Create the pig script without a partnered python udf 
  #
  def pigscript
    script_name = shift_argument
    unless script_name
      error("Usage: mortar generate:pigscript SCRIPTNAME\nMust specify SCRIPTNAME.")
    end
    options[:skip_udf] ||= false
    
    script_generator = Mortar::Generators::PigscriptGenerator.new
    script_generator.generate_pigscript(script_name, project, options)
  end

  # generate:macro [MACRONAME]
  #
  # Generate a new pig macro.
  #
  def macro
    macro_name = shift_argument
    unless macro_name
      error("Usage: mortar generate:macro MACRONAME\nMust specify MACRONAME.")
    end
    
    macro_generator = Mortar::Generators::MacroGenerator.new
    macro_generator.generate_macro(macro_name, project, options)
  end

end