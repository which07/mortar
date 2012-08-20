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
      illustrate_id = api.post_illustrate(project.name, pigscript.name, alias_name, git_ref).body["illustrate_id"]
    end
    
    last_illustrate_result = nil
    while last_illustrate_result.nil? || (! Mortar::API::Illustrate::STATUSES_COMPLETE.include?(last_illustrate_result["status"]))
      sleep polling_interval
      current_illustrate_result = api.get_illustrate(illustrate_id, :exclude_result => true).body
      if last_illustrate_result.nil? || (last_illustrate_result["status"] != current_illustrate_result["status"])
        display(" ... #{current_illustrate_result['status']}")
      end
      
      last_illustrate_result = current_illustrate_result
    end
    
    case last_illustrate_result['status']
    when Mortar::API::Illustrate::STATUS_FAILURE
      error_message = "Illustrate failed with #{last_illustrate_result['error_type'] || 'error'}"
      if line_number = last_illustrate_result["line_number"]
        error_message += " at Line #{line_number}"
        if column_number = last_illustrate_result["column_number"]
          error_message += ", Column #{column_number}"
        end
      end
      error_message += ":\n\n#{last_illustrate_result['error_message']}"
      error(error_message)
    when Mortar::API::Illustrate::STATUS_KILLED
      error("Illustrate killed by user.")
    when Mortar::API::Illustrate::STATUS_SUCCESS
      web_result_url = last_illustrate_result['web_result_url']
      display("Illustrate results available at #{web_result_url}")
      action("Opening web browser to show results") do
        require "launchy"
        Launchy.open(web_result_url).join
      end
    else
      raise RuntimeError, "Unknown illustrate status: #{last_illustrate_result['status']} for illustrate_id: #{illustrate_id}"
    end
  end
end
