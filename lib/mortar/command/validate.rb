require "mortar/command/base"
require "mortar/snapshot"

# manage pig scripts
#
class Mortar::Command::Validate < Mortar::Command::Base
  
  include Mortar::Snapshot
    
  # validate [PIGSCRIPT]
  #
  # Validate a pig script.  Checks script for problems with:
  #    * Pig syntax
  #    * Python syntax
  #    * S3 data access
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  #
  # Examples:
  #
  # $ mortar validate
  # 
  # TBD
  #
  def index
    pigscript_name = shift_argument
    unless pigscript_name
      error("Usage: mortar validate PIGSCRIPT\nMust specify PIGSCRIPT.")
    end
    validate_arguments!
    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)
    git_ref = create_and_push_snapshot_branch(git, project)
    
    validate_id = nil
    action("Starting validate", {:success => "started"}) do
      validate_id = api.post_validate(project.name, pigscript.name, git_ref, :parameters => pig_parameters).body["validate_id"]
    end
        
    validate_result = nil
    display
    ticking(polling_interval) do |ticks|
      validate_result = api.get_validate(validate_id).body
      is_finished =
        Mortar::API::Validate::STATUSES_COMPLETE.include?(validate_result["status"])
        
      redisplay("Validate status: %s %s" % [
        validate_result['status'],
        is_finished ? " " : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
        break
      end
    end
    
    case validate_result['status']
    when Mortar::API::Validate::STATUS_FAILURE
      error_message = "Validate failed with #{validate_result['error_type'] || 'error'}"
      if line_number = validate_result["line_number"]
        error_message += " at Line #{line_number}"
        if column_number = validate_result["column_number"]
          error_message += ", Column #{column_number}"
        end
      end
      error_context = get_error_message_context(validate_result['error_message'])
      error_message += ":\n\n#{validate_result['error_message']}\n\n#{error_context}"
      error(error_message)
    when Mortar::API::Validate::STATUS_KILLED
      error("Validate killed by user.")
    when Mortar::API::Validate::STATUS_SUCCESS
      display("Your script is valid.")
    else
      raise RuntimeError, "Unknown validate status: #{validate_result['status']} for validate_id: #{validate_id}"
    end
  end
end
