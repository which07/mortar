require "mortar/generators/generator_base"
module Mortar
  module Generators
    class ProjectGenerator < Base

      def generate_project(project_name, options)

        set_script_binding(project_name, options)
        mkdir project_name, :verbose => false
        @dest_path = File.join(@dest_path, project_name)
        
        copy_file "README.md", "README.md"
        copy_file "gitignore", ".gitignore"
        copy_file "Gemfile", "Gemfile"
        
        mkdir "pigscripts"
        
        inside "pigscripts" do
          generate_file "pigscript.pig", "#{project_name}.pig"
        end
        
        mkdir "macros"
        
        inside "macros" do
          copy_file "gitkeep", ".gitkeep"
        end
        
        mkdir "udfs"
        
        inside "udfs" do
          mkdir "python"
          inside "python" do
            copy_file "python_udf.py", "#{project_name}.py"
          end
        end
        
        display_run("bundle install")
        `cd #{project_name} && bundle install && cd ..`

      end

      protected

        def set_script_binding(project_name, options)
          options = options
          project_name = project_name
          @script_binding = binding
        end
    end
  end
end