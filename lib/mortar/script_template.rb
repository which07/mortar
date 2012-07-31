require 'erb'

module Mortar
  module ScriptTemplate

    extend self
    
    def expand_script_template(project, script)
      # Use the undocumented "-" mode, allowing <%= blah -%> to expand without newlines
      template = ERB.new(script.code, nil, "-")
      template.result(script_binding(project))
    end

    protected

    def script_binding(project)
      # create a binding that includes everything in the project
      pigscripts = project.pigscripts
      datasets = project.datasets
      binding
    end

  end
end
