require "mortar/command/base"

## manage projects
#
class Mortar::Command::Projects < Mortar::Command::Base
  
  # project [PROJECT_NAME]
  #
  # Initialize a Mortar project.
  #
  # Examples:
  #
  # $ mortar projects
  def index
    #project_name = shift_argument
    #unless project_name
    #  error("Usage: mortar project PROJECT_NAME\nMust specify PROJECT_NAME.")
    #end
    #display(" ... create project: #{project_name}")
    display("Hello World")
  end
end
