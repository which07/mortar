require "mortar/generators/generator_base"
module Mortar
  module Generators
    class MacroGenerator < Base

      def initialize
        super
        @src_path = File.expand_path("../template", __FILE__)
        @dest_path = Dir.pwd
      end

      def new_macro(macro_name, project, options)
        copy_file "<%macro_name%>.pig", "macros/#{macro_name}.pig", :recursive => true
      end
      
    end
  end
end