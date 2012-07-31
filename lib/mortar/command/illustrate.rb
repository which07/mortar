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
    expanded_script = expand_script_template(project, pigscript)
    
    # write to tmp for later use
    expanded_script_filename = "#{pigscript_name}.#{Time.now.strftime("%F-%T:%L")}.pig"
    write_to_file(expanded_script, File.join(project.tmp_path, expanded_script_filename))
    
    # create / push a snapshot branch
    snapshot_branch = git.create_snapshot_branch()
    git.push(project.remote, snapshot_branch)
    
    # make the illustrate API request, fetching illustrate ID
    
    # poll for results
    
    # handle success / failure
    
  end

end
