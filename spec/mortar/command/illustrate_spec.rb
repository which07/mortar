require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/illustrate'

module Mortar::Command
  describe Illustrate do
    
    before(:each) do
      stub_core
      
      # stop destructive git operations from happening
      @git = Mortar::Git::Git.new
    end
    
    context("index") do
      
      it "errors when an alias is not provided" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("illustrate my_script", p)
          stderr.should == <<-STDERR
 !    Usage: mortar illustrate PIGSCRIPT ALIAS
 !    Must specify PIGSCRIPT and ALIAS.
STDERR
        end
      end

      it "errors when no remote exists in the project" do
        with_git_initialized_project do |p|
          @git.git('remote rm mortar')
          p.remote = nil
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("illustrate my_script my_alias", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find git remote for project myproject
STDERR
        end
      end

      it "errors when requested pigscript cannot be found" do
        with_git_initialized_project do |p|
          stderr, stdout = execute("illustrate does_not_exist my_alias", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    No pigscripts found
 STDERR
        end
      end
      
      it "requests and reports on a successful illustrate" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          @git.should_receive(:push).with("mortar", instance_of(String))
          stderr, stdout = execute("illustrate my_script my_alias", p, @git)
          # ensure that the expanded file was written
          Dir.exists?(p.tmp_path).should be_true
          Dir[p.tmp_path].size.should == 1
        end
      end
      
      it "requests and reports on a failed illustrate" do
      end
      
    end
  end
end
