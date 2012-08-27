require "mortar/generators/generator_base"
module Mortar
  module Generators
    class MacroGenerator < Base

      def generate_macro(macro_name, project, options)
        copy_file "macro.pig", "macros/#{macro_name}.pig", :recursive => true
      end
      
    end
  end
end