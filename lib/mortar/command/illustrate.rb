require "mortar/command/base"
require "mortar/snapshot"

# manage pig scripts
#
class Mortar::Command::Illustrate < Mortar::Command::Base
  
  include Mortar::Snapshot
    
  # illustrate [PIGSCRIPT] [ALIAS]
  #
  # Illustrate the effects and output of a pigscript.
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  #
  # Examples:
  #
  # $ mortar illustrate
  # 
  # TBD
  #
  def index
    pigscript_name = shift_argument
    alias_name = shift_argument
    unless pigscript_name && alias_name
      error("Usage: mortar illustrate PIGSCRIPT ALIAS\nMust specify PIGSCRIPT and ALIAS.")
    end
    validate_arguments!
    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)
    git_ref = create_and_push_snapshot_branch(git, project)
    
    illustrate_id = nil
    action("Starting illustrate", {:success => "started"}) do
      illustrate_id = api.post_illustrate(project.name, pigscript.name, alias_name, git_ref, :parameters => pig_parameters).body["illustrate_id"]
    end
        
    illustrate_result = nil
    display
    ticking(polling_interval) do |ticks|
      illustrate_result = api.get_illustrate(illustrate_id, :exclude_result => true).body
      is_finished =
        Mortar::API::Illustrate::STATUSES_COMPLETE.include?(illustrate_result["status"])
        
      redisplay("Illustrate status: %s %s" % [
        illustrate_result['status'],
        is_finished ? " " : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
        break
      end
    end
    
    case illustrate_result['status']
    when Mortar::API::Illustrate::STATUS_FAILURE
      error_message = "Illustrate failed with #{illustrate_result['error_type'] || 'error'}"
      if line_number = illustrate_result["line_number"]
        error_message += " at Line #{line_number}"
        if column_number = illustrate_result["column_number"]
          error_message += ", Column #{column_number}"
        end
      end
      error_message += ":\n\n#{illustrate_result['error_message']}"
      error(error_message)
    when Mortar::API::Illustrate::STATUS_KILLED
      error("Illustrate killed by user.")
    when Mortar::API::Illustrate::STATUS_SUCCESS
      web_result_url = illustrate_result['web_result_url']
      display("Results available at #{web_result_url}")
      action("Opening web browser to show results") do
        require "launchy"
        Launchy.open(web_result_url).join
      end
    else
      raise RuntimeError, "Unknown illustrate status: #{illustrate_result['status']} for illustrate_id: #{illustrate_id}"
    end
  end
end
