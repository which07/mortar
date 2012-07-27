require "spec_helper"
require 'fakefs/spec_helpers'
require "mortar/project"

module Mortar
  describe Project do
    # use FakeFS file system
    include FakeFS::SpecHelpers
    
    include Mortar::Project
    

    context "pigscripts" do

      it "raise when unable to find pigscripts dir" do
        lambda { pigscripts }.should raise_error(Mortar::Project::ProjectError) 
      end
      
      it "finds no pigscripts in an empty dir" do
        with_blank_project do
          pigscripts.should == {}
        end
      end
      
      it "finds a single pigscript" do
        with_blank_project do
          pigscript_path = File.join(pigscripts_dir, "my_script.pig")
          write_file pigscript_path
          pigscripts.should == {"my_script" => pigscript_path}
        end
      end

      it "finds a script stored in a subdirectory" do
        with_blank_project do
          pigscript_path = File.join(pigscripts_dir, "subdir", "my_script.pig")
          write_file pigscript_path
          pigscripts.should == {"my_script" => pigscript_path}
        end
      end
      
      it "finds multiple scripts in subdirectories with the same name" do
      end
    end
  end
end
