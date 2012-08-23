require "mortar/generators/generator_base"
module Mortar
  module Generators
    class UDFGenerator < Base

      def initialize
        super
        @src_path = File.expand_path("../template", __FILE__)
        @dest_path = Dir.pwd
      end

      def new_python_udf(udf_name, project, options)
        copy_file "<%udf_name%>.py", "udfs/python/#{udf_name}.py", :recursive => true
      end
      
    end
  end
end