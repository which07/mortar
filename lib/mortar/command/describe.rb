require "mortar/command/base"
require "mortar/snapshot"

# manage pig scripts
#
class Mortar::Command::Describe < Mortar::Command::Base
  
  include Mortar::Snapshot
    
  # describe [PIGSCRIPT] [ALIAS]
  #
  # Describe the schema of an alias and all of its ancestors.
  #
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  #
  # Examples:
  #
  # $ mortar describe
  # 
  # TBD
  #
  def index
    pigscript_name = shift_argument
    alias_name = shift_argument
    unless pigscript_name && alias_name
      error("Usage: mortar describe PIGSCRIPT ALIAS\nMust specify PIGSCRIPT and ALIAS.")
    end
    validate_arguments!
    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)
    git_ref = create_and_push_snapshot_branch(git, project)
    
    describe_id = nil
    action("Starting describe", {:success => "started"}) do
      describe_id = api.post_describe(project.name, pigscript.name, alias_name, git_ref, :parameters => pig_parameters).body["describe_id"]
    end
        
    describe_result = nil
    display
    ticking(polling_interval) do |ticks|
      describe_result = api.get_describe(describe_id, :exclude_result => true).body
      is_finished =
        Mortar::API::Describe::STATUSES_COMPLETE.include?(describe_result["status"])
        
      redisplay("Describe status: %s %s" % [
        describe_result['status'],
        is_finished ? " " : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
        break
      end
    end
    
    case describe_result['status']
    when Mortar::API::Describe::STATUS_FAILURE
      error_message = "Describe failed with #{describe_result['error_type'] || 'error'}"
      if line_number = describe_result["line_number"]
        error_message += " at Line #{line_number}"
        if column_number = describe_result["column_number"]
          error_message += ", Column #{column_number}"
        end
      end
      error_context = get_error_message_context(describe_result['error_message'])
      error_message += ":\n\n#{describe_result['error_message']}\n\n#{error_context}"
      error(error_message)
    when Mortar::API::Describe::STATUS_KILLED
      error("Describe killed by user.")
    when Mortar::API::Describe::STATUS_SUCCESS
      web_result_url = describe_result['web_result_url']
      display("Results available at #{web_result_url}")
      action("Opening web browser to show results") do
        require "launchy"
        Launchy.open(web_result_url).join
      end
    else
      raise RuntimeError, "Unknown describe status: #{describe_result['status']} for describe_id: #{describe_id}"
    end
  end
end
