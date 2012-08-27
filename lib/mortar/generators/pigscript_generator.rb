require "mortar/generators/generator_base"
module Mortar
  module Generators
    class PigscriptGenerator < Base

      def generate_pigscript(script_name, project, options)
        puts "generate sciprt"
        set_script_binding(script_name, options)


        generate_file "pigscript.pig", "pigscripts/#{script_name}.pig", :recursive => true
        copy_file "python_udf.py", "udfs/python/#{script_name}.py", :recursive => true if not options[:skip_udf]
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