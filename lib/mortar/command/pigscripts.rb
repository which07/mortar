require "mortar/project"
require "mortar/command/base"

# manage pig scripts
#
class Mortar::Command::PigScripts < Mortar::Command::Base
  
  include Mortar::Project

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
    all_pigscripts = pigscripts
    unless all_pigscripts.empty?
      styled_header("pigscripts")
      styled_array(all_pigscripts.keys)
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
    
    all_pigscripts = pigscripts
    unless pigscript_path = all_pigscripts[name]
      available_scripts = all_pigscripts.empty? ? "No pigscripts found" : "Available scripts:\n#{pigscripts.keys.join("\n")}"
      error("Unable to find pigscript #{name}\n#{available_scripts}")
    end
  end

end
