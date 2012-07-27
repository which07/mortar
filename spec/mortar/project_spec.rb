require "spec_helper"
require 'fakefs/spec_helpers'
require "mortar/project"

module Mortar
  describe Project do
    # use FakeFS file system
    include FakeFS::SpecHelpers    
        
    context "pigscripts" do

      it "raise when unable to find pigscripts dir" do
        with_blank_project do |p|
          FileUtils.rm_rf p.pigscripts_path
          lambda { p.pigscripts }.should raise_error(Mortar::Project::ProjectError)
        end
      end
      
      it "finds no pigscripts in an empty dir" do
        with_blank_project do |p|
          p.pigscripts.none?.should be_true
        end
      end
      
      it "finds a single pigscript" do
        with_blank_project do |p|
          pigscript_path = File.join(p.pigscripts_path, "my_script.pig")
          write_file pigscript_path
          p.pigscripts.my_script.name.should == "my_script"
          p.pigscripts.my_script.path.should == pigscript_path
        end
      end

      it "finds a script stored in a subdirectory" do
        with_blank_project do |p|
          pigscript_path = File.join(p.pigscripts_path, "subdir", "my_script.pig")
          write_file pigscript_path
          p.pigscripts.my_script.name.should == "my_script"
          p.pigscripts.my_script.path.should == pigscript_path
        end
      end
      
      it "finds multiple scripts in subdirectories with the same name" do
      end
    end
  end
end
