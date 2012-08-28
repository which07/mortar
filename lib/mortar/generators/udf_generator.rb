require "mortar/generators/generator_base"
module Mortar
  module Generators
    class UDFGenerator < Base

      def generate_python_udf(udf_name, project, options)
        copy_file "python_udf.py", "udfs/python/#{udf_name}.py", :recursive => true
      end
      
    end
  end
end