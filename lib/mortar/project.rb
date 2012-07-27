module Mortar
  module Project
    class ProjectError < RuntimeError; end
    
    extend self
    
    def pigscripts_dir
      File.join(Dir.pwd, "pigscripts")
    end
    
    def pigscripts
      unless Dir.exists?(pigscripts_dir)
        raise ProjectError, "Unable to find pigscripts directory in project"
      end
      
      # get {script_name => full_path}
      pigscripts_paths = Dir[File.join(pigscripts_dir, "**", "*.pig")]
      pigscripts_paths_hsh = pigscripts_paths.collect{|path| [File.basename(path, ".pig"), path]}.flatten
      Hash[*pigscripts_paths_hsh]
    end    
  end
end
