require "mortar/command/base"

GIT_HOST = "github.com"
GIT_ORGANIZATION = "mortarcode"

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
      error("Can only create a mortar project for an existing git project.")
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
      git.remote_add("mortar", "git@%s:%s/%s.git" % [GIT_HOST, GIT_ORGANIZATION, last_project_result['github_repo_name']])
    else
      raise RuntimeError, "Unknown project status: #{last_project_result['status']} for project_id: #{project_id}"
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
      error("Invalid project name: #{name}")
    end
    git.clone(GIT_HOST, GIT_ORGANIZATION, project['github_repo_name'], project['name'])
  end
end
