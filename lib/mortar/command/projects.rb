#
# Copyright 2012 Mortar Data Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "fileutils"

require "mortar/command"
require "mortar/command/base"
require "mortar/git"

# manage projects (create, clone)
#
class Mortar::Command::Projects < Mortar::Command::Base
  
  # projects
  #
  # Display the available set of projects
  def index
    validate_arguments!
    projects = api.get_projects().body["projects"]
    if projects.any?
      styled_header("projects")
      styled_array(projects.collect{ |x| x["name"] })
    else
      display("You have no projects.")
    end
  end
  
  # projects:delete PROJECTNAME
  #
  # Delete a mortar project
  def delete
    name = shift_argument
    unless name
      error("Usage: mortar projects:delete PROJECTNAME\nMust specify PROJECTNAME.")
    end
    validate_arguments!
    
    project_id = nil
    action("Sending request to delete project: #{name}") do
      api.delete_project(name).body["project_id"]
    end
    display "\nYour project has been deleted."
    
  end
  
  # projects:create PROJECTNAME
  #
  # Generate and register a new Mortar project for code in the current directory, with the name PROJECTNAME.
  def create
    name = shift_argument
    unless name
      error("Usage: mortar projects:create PROJECTNAME\nMust specify PROJECTNAME")
    end
    
    Mortar::Command::run("generate:project", [name])
    FileUtils.cd(name)
    git.git_init
    git.git("add .")
    git.git("commit -m \"Mortar project scaffolding\"")
    Mortar::Command::run("projects:register", [name])
    git.git("push mortar master")
  end
  alias_command "new", "projects:create"
  
  # projects:register PROJECT
  #
  # register a mortar project for the current directory with the name PROJECT
  def register
    name = shift_argument
    unless name
      error("Usage: mortar projects:register PROJECT\nMust specify PROJECT.")
    end
    validate_arguments!
    
    unless git.has_dot_git?
      # check if we're in the parent directory
      if File.exists? name
        error("mortar projects:register must be run from within the project directory.\nPlease \"cd #{name}\" and rerun this command.")
      else
        error("No git repository found in the current directory.\nPlease initialize a git repository for this project, and then rerun the register command.\nTo initialize your project in git, use:\n\ngit init\ngit add .\ngit commit -a -m \"first commit\"")
      end
    end
    
    # ensure the project name does not already exist
    project_names = api.get_projects().body["projects"].collect{|p| p['name']}
    if project_names.include? name
      error("Your account already contains a project named #{name}.\nPlease choose a different name for your new project, or clone the existing #{name} code using:\n\nmortar projects:clone #{name}")
    end
    
    unless git.remotes(git_organization).empty?
      begin
        error("Currently in project: #{project.name}.  You can not register a new project inside of an existing mortar project.")
      rescue Mortar::Command::CommandFailed => cf
        error("Currently in an existing Mortar project.  You can not register a new project inside of an existing mortar project.")
      end
    end
    
    project_id = nil
    action("Sending request to register project: #{name}") do
      project_id = api.post_project(name).body["project_id"]
    end
    
    project_result = nil
    project_status = nil
    display
    ticking(polling_interval) do |ticks|
      project_result = api.get_project(project_id).body
      project_status = project_result.fetch("status_code", project_result["status"])
      project_description = project_result.fetch("status_description", project_status)
      is_finished = Mortar::API::Projects::STATUSES_COMPLETE.include?(project_status)

      redisplay("Status: %s %s" % [
        project_description + (is_finished ? "" : "..."),
        is_finished ? " " : spinner(ticks)],
        is_finished) # only display newline on last message
      if is_finished
        display
        break
      end
    end
    
    case project_status
    when Mortar::API::Projects::STATUS_FAILED
      error("Project registration failed.\nError message: #{project_result['error_message']}")
    when Mortar::API::Projects::STATUS_ACTIVE
      git.remote_add("mortar", project_result['git_url'])
      display "Your project is ready for use.  Type 'mortar help' to see the commands you can perform on the project.\n\n"
    else
      raise RuntimeError, "Unknown project status: #{project_status} for project_id: #{project_id}"
    end
    
  end
  alias_command "register", "projects:register"

  # projects:set_remote PROJECT
  #
  # Adds the Mortar remote to the local git project. This is necessary for successfully executing many of the Mortar commands.
  #
  def set_remote
    project_name = shift_argument

    unless project_name
      error("Usage: mortar projects:set_remote PROJECT\nMust specify PROJECT.")
    end

    unless git.has_dot_git?
      error("Can only set the remote for an existing git project.  Please run:\n\ngit init\ngit add .\ngit commit -a -m \"first commit\"\n\nto initialize your project in git.")
    end

    if git.remotes(git_organization).include?("mortar")
      display("The remote has already been set for project: #{project_name}")
      return
    end

    projects = api.get_projects().body["projects"]
    project = projects.find { |p| p['name'] == project_name}
    unless project
      error("No project named: #{project_name} exists. You can create this project using:\n\n mortar projects:create")
    end

    git.remote_add("mortar", project['git_url'])
    display("Successfully added the mortar remote to the #{project_name} project")

  end
  
  # projects:clone PROJECT
  #
  # clone the mortar project PROJECT into the current directory.
  #
  def clone
    name = shift_argument
    unless name
      error("Usage: mortar projects:clone PROJECT\nMust specify PROJECT.")
    end
    validate_arguments!
    projects = api.get_projects().body["projects"]
    project = projects.find{|p| p['name'] == name}
    unless project
      error("No project named: #{name} exists.  Your valid projects are:\n#{projects.collect{ |x| x["name"]}.join("\n")}")
    end

    project_dir = File.join(Dir.pwd, project['name'])
    unless !File.exists?(project_dir)
      error("Can't clone project: #{project['name']} since directory with that name already exists.")
    end

    git.clone(project['git_url'], project['name'])

    display "\nYour project is ready for use.  Type 'mortar help' to see the commands you can perform on the project.\n\n"
  end
end
