require "erb"

module Mortar
  module Generators
    class Base 
      include FileUtils
      include Mortar::Helpers

      def initialize
        @src_path = ""
        @dest_path = ""
        @rel_path = ""
        @binding_variables = {}
      end
      
      def inside(folder)
        rel_backup = @rel_path
        @rel_path = File.join(@rel_path, folder)
        yield
        @rel_path = rel_backup
      end

      def copy_file(src_file, dest_file, options={ :recursive => false })
        src_path = File.join(@src_path, @rel_path, src_file)
        dest_path = File.join(@dest_path, @rel_path, dest_file)
        msg = File.join(@rel_path, dest_file)[1..-1]

        if File.exists?(dest_path)
          if FileUtils.compare_file(src_path, dest_path)
            display_identical(msg)
          else
            display_conflict(msg)
          end 
        else
          FileUtils.mkdir_p(File.dirname(dest_path)) if options[:recursive]
          FileUtils.cp(src_path, dest_path)
          display_create(msg)  
        end
      end

      def directory(folder, options={ :verbose => true })
        dest_path = File.join(@dest_path, @rel_path, folder)
        msg = File.join(@rel_path, folder)[1..-1]

        if File.exists?(dest_path) 
          display_exists(options[:verbose] ? msg : "") 
        else
          FileUtils.mkdir(dest_path)
          display_create(options[:verbose] ? msg : "")
        end
      end

      def template(src_file, dest_file, options={ :recursive => false })
        src_path = File.join(@src_path, @rel_path, src_file)
        dest_path = File.join(@dest_path, @rel_path, dest_file)
        msg = File.join(@rel_path, dest_file)[1..-1]

        erb = ERB.new(File.read(src_path), 0, "%<>")

        result = erb.result(@script_binding)
        

        if File.exists?(dest_path)
          if result == File.read(dest_path) 
            display_identical(msg)
          else
            display_conflict(msg)
          end 
        else
          FileUtils.mkdir_p(File.dirname(dest_path)) if options[:recursive]
          file = File.new(dest_path, "w")
          file.write(result)
          file.close
          display_create(msg)  
        end
      end

      protected

        def set_script_binding(options)
          options = options
          binding
        end

    end
  end
end