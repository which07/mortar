require 'fileutils'

module Mortar
  module Project
    class ProjectError < RuntimeError; end
    
    class Project
      attr_accessor :name
      attr_accessor :remote
      attr_accessor :root_path
      
      def initialize(name, root_path, remote)
        @name = name
        @root_path = root_path
        @remote = remote
      end
      
      def datasets_path
        File.join(@root_path, "datasets")
      end
            
      def datasets
        @datasets ||= DataSets.new(
          datasets_path,
          "datasets",
          ".pig")
        @datasets
      end
      
      def pigscripts_path
        File.join(@root_path, "pigscripts")
      end

      def pigscripts
        @pigscripts ||= PigScripts.new(
          pigscripts_path,
          "pigscripts",
          ".pig")
        @pigscripts
      end
      
      def tmp_path
        path = File.join(@root_path, "tmp")
        unless Dir.exists? path
          FileUtils.mkdir_p path
        end
        path
      end
    end
    
    class ProjectEntity
      
      include Enumerable
      
      def initialize(path, name, filename_extension)
        @path = path
        @name = name
        @filename_extension = filename_extension
        @elements = elements
      end
      
      def method_missing(method, *args)
        method_name = method.to_s
        return @elements[method_name] if @elements[method_name]
        super
      end
      
      def each
        @elements.each {|key, value| yield [key, value]}
      end
      
      def [](key)
        @elements[key]
      end
      
      def keys
        @elements.keys
      end
      
      protected
      
      def element_name(element_path)
        File.basename(element_path, @filename_extension)
      end

      def elements
        unless Dir.exists? @path
          raise ProjectError, "Unable to find #{@name} directory in project"
        end

        # get {script_name => full_path}
        file_paths = Dir[File.join(@path, "**", "*#{@filename_extension}")]
        file_paths_hsh = file_paths.collect{|element_path| [element_name(element_path), element(element_name(element_path), element_path)]}.flatten
        Hash[*file_paths_hsh]
      end
      
      def element(path)
        raise NotImplementedError, "Implement in subclass"
      end
    end
    
    class PigScripts < ProjectEntity
      def element(name, path)
        Script.new(name, path)
      end
    end
    
    class DataSets < ProjectEntity
      def element(name, path)
        Script.new(name, path)
      end
    end
    
    class Script
      
      attr_reader :name
      attr_reader :path
      
      def initialize(name, path)
        @name = name
        @path = path
      end

      def code
        script_file = File.open(@path, "r")
        script_contents = script_file.read
        script_file.close
        script_contents
      end
      
      def to_s
        code
      end
    end
    
  end
end
