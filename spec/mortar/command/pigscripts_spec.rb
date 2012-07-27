require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/pigscripts'

module Mortar::Command
  describe PigScripts do
    
    include Mortar::Project
    
    # use FakeFS file system
    include FakeFS::SpecHelpers
    
    before(:each) do
      stub_core
    end
    
    context("index") do
      
      it "displays a message when no pigscripts found" do
        with_blank_project do
          stderr, stdout = execute("pigscripts")
          stdout.should == <<-STDOUT
You have no pigscripts.
STDOUT
        end
      end
      
      it "displays list of 1 pigscript" do
        with_blank_project do
          write_file(File.join(pigscripts_dir, "my_script.pig"))
          stderr, stdout = execute("pigscripts")
          stdout.should == <<-STDOUT
=== pigscripts
my_script

STDOUT
        end
      end
      
      it "displays list of multiple pigscripts" do
        with_blank_project do
          write_file(File.join(pigscripts_dir, "a_script.pig"))
          write_file(File.join(pigscripts_dir, "b_script.pig"))
          stderr, stdout = execute("pigscripts")
          stdout.should == <<-STDOUT
=== pigscripts
a_script
b_script

STDOUT
        end

      end
      
    end

    context("expand") do
      
      it "errors when no SCRIPT argument provided" do
        stderr, stdout = execute("pigscripts:expand")
        stderr.should == <<-STDERR
 !    Usage: mortar pigscripts:expand SCRIPT
 !    Must specify SCRIPT.
STDERR
      end
      
      it "errors when the pigscript cannot be found" do
        with_blank_project do
          stderr, stdout = execute("pigscripts:expand does_not_exist")
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    No pigscripts found
STDERR
        end
      end
      
      it "displays the other options when a pigscript cannot be found" do
        with_blank_project do
           write_file(File.join(pigscripts_dir, "does_exist.pig"))
           stderr, stdout = execute("pigscripts:expand does_not_exist")
           stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    Available scripts:
 !    does_exist
STDERR
        end
      end
      
      it "returns a pigscript without templates without modification" do
      end
      
      it "returns a pigscript with a dataset template included" do
      end
    end
  end
end
