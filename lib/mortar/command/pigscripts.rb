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

end
