require "mortar/generators/generator_base"
module Mortar
  module Generators
    class AppGenerator < Base

      def initialize
        super
        @src_path = File.expand_path("../template", __FILE__)
        @dest_path = Dir.pwd
      end

      def new_application(project_name, options)

        set_script_binding(project_name, options)
        directory project_name, :verbose => false
        @dest_path = File.join(@dest_path, project_name)
        
        #copy_file "README.md", "README.md"
        copy_file "gitignore", ".gitignore"
        copy_file "Gemfile", "Gemfile"
        
        directory "pigscripts"
        
        inside "pigscripts" do
          template "<%app_name%>.pig", "#{project_name}.pig"
        end
        
        directory "macros"
        
        inside "macros" do
          copy_file "gitkeep", ".gitkeep"
        end
        
        directory "udfs"
        
        inside "udfs" do
          directory "python"
          inside "python" do
            copy_file "<%app_name%>.py", "#{project_name}.py"
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