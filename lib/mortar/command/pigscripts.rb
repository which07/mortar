require 'erb'

require "mortar/project"
require "mortar/command/base"

# manage pig scripts
#
class Mortar::Command::PigScripts < Mortar::Command::Base
  
  # pigscripts
  #
  # display the available set of pigscripts
  #
  #Examples:
  #
  # $ mortar pigscripts
  # 
  # hourly_top_searchers
  # user_engagement
  #
  def index
    # validation
    validate_arguments!
    if project.pigscripts.any?
      styled_header("pigscripts")
      styled_array(project.pigscripts.keys)
    else
      display("You have no pigscripts.")
    end
  end

  # pigscripts:expand SCRIPT
  #
  # expand the templates and macros for a pigscript.
  #
  #Example:
  #
  # $ mortar pigscripts:expand hourly_top_searchers
  # -- MY EXPANDED PIG SCRIPT FOLLOWS
  #
  def expand
    name = shift_argument
    unless name
      error("Usage: mortar pigscripts:expand SCRIPT\nMust specify SCRIPT.")
    end
    validate_arguments!
    
    
    unless pigscript = project.pigscripts[name]
      available_scripts = project.pigscripts.none? ? "No pigscripts found" : "Available scripts:\n#{project.pigscripts.keys.sort.join("\n")}"
      error("Unable to find pigscript #{name}\n#{available_scripts}")
    end
    
    template = ERB.new(pigscript.code, nil, "-")
    result = template.result(erb_binding(project))
    display(result)
  end
  
  protected
  
  def erb_binding(project)
    pigscripts = project.pigscripts
    datasets = project.datasets
    binding
  end
end
