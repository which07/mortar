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

require "mortar/command/base"

## manage projects
#
class Mortar::Command::Projects < Mortar::Command::Base
  
  # projects
  #
  # Display the available set of projects
  #
  #Examples:
  #
  # $ mortar projects
  # 
  #=== projects
  #demo
  #rollup
  #
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
  
  # projects:create PROJECT
  #
  # create a mortar project for the current directory with the name PROJECT
  #
  #Example:
  #
  # $ mortar projects:create my_new_project
  #
  def create
    name = shift_argument
    unless name
      error("Usage: mortar projects:create PROJECT\nMust specify PROJECT.")
    end
    validate_arguments!
    
    unless git.has_dot_git?
      error("Can only create a mortar project for an existing git project.  Please run:\n\ngit init\ngit add .\ngit commit -a -m \"first commit\"\n\nto initialize your project in git.")
    end
    
    unless git.remotes(git_organization).empty?
      begin
        error("Currently in project: #{project.name}.  You can not create a new project inside of an existing mortar project.")
      rescue Mortar::Command::CommandFailed => cf
        error("Currently in an existing Mortar project.  You can not create a new project inside of an existing mortar project.")
      end
    end
    
    project_id = nil
    action("Creating project", {:success => "started"}) do
      project_id = api.post_project(name).body["project_id"]
    end
    
    last_project_result = nil
    while last_project_result.nil? || (! Mortar::API::Projects::STATUSES_COMPLETE.include?(last_project_result["status"]))
      sleep polling_interval
      current_project_result = api.get_project(project_id).body
      if last_project_result.nil? || (last_project_result["status"] != current_project_result["status"])
        display(" ... #{current_project_result['status']}")
      end
      
      last_project_result = current_project_result
    end
    
    case last_project_result['status']
    when Mortar::API::Projects::STATUS_FAILED
      error("Project creation failed.\nError message: #{last_project_result['error_message']}")
    when Mortar::API::Projects::STATUS_ACTIVE
      git.remote_add("mortar", last_project_result['git_url'])
    else
      raise RuntimeError, "Unknown project status: #{last_project_result['status']} for project_id: #{project_id}"
    end
    
    
  end

  # projects:set_remote PROJECT
  #
  # adds the mortar remote to the local git project
  #
  #Example:
  #
  # $ mortar projects:set_remote my_project
  #
  def set_remote
    project_name = shift_argument

    unless project_name
      error("Usage: mortar projects:set_remote PROJECT\nMust specify PROJECT.")
    end

    unless git.has_dot_git?
      error("Can only create a mortar project for an existing git project.  Please run:\n\ngit init\ngit add .\ngit commit -a -m \"first commit\"\n\nto initialize your project in git.")
    end

    display git.remotes(git_organization)
    if git.remotes(git_organization).include?("mortar")
      error("The remote has already been set for project: #{project_name}")
    end

    projects = api.get_projects().body["projects"]
    project = projects.find { |p| p['name'] == project_name}
    unless project
      error("No project named: #{project_name} exists. You can create this project using:\n\n mortar projects:create")
    end

    case project['status']
    when Mortar::API::Projects::STATUS_FAILED
      error("unable to add remote for project named: #{project_name} because it failed to be created. Try recreating it by using:\n\n mortar projects:create")
    when Mortar::API::Projects::STATUS_ACTIVE
      git.remote_add("mortar", project['git_url'])
      display("Successfully added the mortar remote to the #{project_name} project")
    else
      raise RuntimeError, "Unknown project status: #{project['status']}"
    end
  end
  
  # projects:clone PROJECT
  #
  # clone the mortar project PROJECT into the current directory.
  #
  #Example:
  #
  # $ mortar projects:clone my_new_project
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
  end
end
