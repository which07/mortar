require "mortar/command/base"
require "mortar/script_template"

# manage pig scripts
#
class Mortar::Command::Illustrate < Mortar::Command::Base
  
  include Mortar::ScriptTemplate
    
  # illustrate
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
    
    unless project.root_path
      # TODO: make illustrate work if you pass in --project and are in the project directory
      # TODO: make illustrate work if code not deployed locally
      error("illustrate must be run from the project directory")
    end
    
    unless project.remote
      # TODO: better, more centralized error message
      error("Unable to find git remote for project #{project.name}")
    end
    
    unless pigscript = project.pigscripts[pigscript_name]
      # FIXME ddaniels: duplicated in pigscripts -- extract to method in helpers
      available_scripts = project.pigscripts.none? ? "No pigscripts found" : "Available scripts:\n#{project.pigscripts.keys.sort.join("\n")}"
      error("Unable to find pigscript #{pigscript_name}\n#{available_scripts}")
    end
        
    # expand the template
    action("Expanding templates in pigscript #{pigscript_name}") do 
      expanded_script = expand_script_template(project, pigscript)
    
      # write to tmp for later use
      expanded_script_filename = "#{pigscript_name}.#{Time.now.strftime("%F-%T:%L")}.pig"
      expanded_script_path = File.join(project.tmp_path, expanded_script_filename)
      write_to_file(expanded_script, File.join(project.tmp_path, expanded_script_filename))
      status("expanded to  #{expanded_script_path}")
    end
    
    # create / push a snapshot branch
    snapshot_branch = action("Taking code snapshot") do
      git.create_snapshot_branch()
    end
    
    action("Sending code snapshot to Mortar") do
      git.push(project.remote, snapshot_branch)
    end
    
    display("Starting illustrate...")
    illustrate_id = api.post_illustrate(project.name, pigscript.name, alias_name, snapshot_branch)["illustrate_id"]
    
    last_illustrate_result = nil
    while last_illustrate_result.nil? || (! Mortar::API::Illustrate::STATUSES_COMPLETE.include?(last_illustrate_result["status"]))
      sleep polling_interval
      current_illustrate_result = api.get_illustrate(illustrate_id)
      if last_illustrate_result.nil? || (last_illustrate_result["status"] != current_illustrate_result["status"])
        display(" ... #{current_illustrate_result['status']}")
      end
      
      last_illustrate_result = current_illustrate_result
    end
    
    case last_illustrate_result['status']
    when Mortar::API::Illustrate::STATUS_FAILURE
      error("Illustrate failed.\nError message: #{last_illustrate_result['error']}")
    when Mortar::API::Illustrate::STATUS_KILLED
      error("Illustrate killed by user.")
    when Mortar::API::Illustrate::STATUS_SUCCESS
      result_url = last_illustrate_result['result_url']
      display("Illustrate results available at #{result_url}")
      action("Opening web browser to show results...") do
        require "launchy"
        Launchy.open(result_url).join
      end
    else
      raise RuntimeError, "Unknown illustrate status: #{last_illustrate_result['status']} for illustrate_id: #{illustrate_id}"
    end
  end
end
