require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/project'
require 'mortar/command/pigscripts'

module Mortar::Command
  describe PigScripts do
    
    # use FakeFS file system
    include FakeFS::SpecHelpers
    
    before(:each) do
      stub_core
    end
    
    context("index") do
      
      it "displays a message when no pigscripts found" do
        with_blank_project do |p|
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
You have no pigscripts.
STDOUT
        end
      end
      
      it "displays list of 1 pigscript" do
        with_blank_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
=== pigscripts
my_script

STDOUT
        end
      end
      
      it "displays list of multiple pigscripts" do
        with_blank_project do |p|
          write_file(File.join(p.pigscripts_path, "a_script.pig"))
          write_file(File.join(p.pigscripts_path, "b_script.pig"))
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
=== pigscripts
a_script
b_script

STDOUT
        end
      end      
    end
  end
end
