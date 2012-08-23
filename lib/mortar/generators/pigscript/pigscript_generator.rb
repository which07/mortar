require "mortar/generators/generator_base"
module Mortar
  module Generators
    class PigscriptGenerator < Base

      def initialize
        super
        @src_path = File.expand_path("../template", __FILE__)
        @dest_path = Dir.pwd
      end

      def new_pigscript(script_name, project, options)
        set_script_binding(script_name, options)

        template "<%script_name%>.pig", "pigscripts/#{script_name}.pig", :recursive => true
        copy_file "<%script_name%>.py", "udfs/python/#{script_name}.py", :recursive => true if not options[:skip_udf]
      end

      protected

        def set_script_binding(script_name, options)
          options = options
          script_name = script_name
          @script_binding = binding
        end 
      
    end
  end
end