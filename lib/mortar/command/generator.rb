require "mortar/command/base"

# generate new projects and scaffolding
#
class Mortar::Command::Generate < Mortar::Command::Base
  
  # generate:application
  #
  # generate new application
  # 
  #
  # Examples:
  #
  # $ mortar generate:application
  # 
  # TBD
  # 
  def application
    project_name = shift_argument
    unless project_name
      error("Usage: mortar new PROJECTNAME\nMust specify PROJECTNAME.")
    end
    pigscript_name = project_name
    app_generator = Mortar::Generators::AppGenerator.new
    app_generator.new_application(project_name, options)
  end
  alias_command "new", "generate:application"



  # generate:python_udf
  #
  # generate new python user defined function
  # 
  #
  # Examples:
  #
  # $ mortar generate:python_udf UDFNAME
  # 
  # TBD
  # 
  def python_udf
    udf_name = shift_argument
    unless udf_name
      error("Usage: mortar generate:python_udf UDFNAME\nMust specify UDFNAME.")
    end
    udf_generator = Mortar::Generators::UDFGenerator.new
    udf_generator.new_python_udf(udf_name, project, options)

  end

  # generate:pigscript
  #
  # generate new pig script
  #
  # --skip-udf # Create the pig script without a partnered python udf 
  #
  # Examples:
  #
  # $ mortar generate:pigscript SCRIPTNAME
  # 
  # TBD
  # 
  def pigscript
    script_name = shift_argument
    unless script_name
      error("Usage: mortar generate:pigscript SCRIPTNAME\nMust specify SCRIPTNAME.")
    end
    options[:skip_udf] ||= false
    
    script_generator = Mortar::Generators::PigscriptGenerator.new
    script_generator.new_pigscript(script_name, project, options)

  end

  # generate:macro
  #
  # generate new macro
  #
  #
  # Examples:
  #
  # $ mortar generate:macro MACRONAME
  # 
  # TBD
  # 
  def macro
    macro_name = shift_argument
    unless macro_name
      error("Usage: mortar generate:pigscript MACRONAME\nMust specify MACRONAME.")
    end
    
    macro_generator = Mortar::Generators::MacroGenerator.new
    macro_generator.new_macro(macro_name, project, options)

  end


  
end