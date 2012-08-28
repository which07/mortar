require "mortar/generators/generator_base"
module Mortar
  module Generators
    class MacroGenerator < Base

      def generate_macro(macro_name, project, options)
        set_script_binding(macro_name, options)
        generate_file "macro.pig", "macros/#{macro_name}.pig", :recursive => true
      end
      
      protected

        def set_script_binding(macro_name, options)
          options = options
          macro_name = macro_name
          @script_binding = binding
        end

    end
  end
end