require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/illustrate'
require 'mortar/api/illustrate'
require 'launchy'

module Mortar::Command
  describe Illustrate do
    
    before(:each) do
      stub_core      
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
          # stub api requests
          illustrate_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          illustrate_url = "https://api.mortardata.com/illustrates/#{illustrate_id}"
          
          
          mock(Mortar::Auth.api).post_illustrate("myproject", "my_script", "my_alias", is_a(String)) {Excon::Response.new(:body => {"illustrate_id" => illustrate_id})}
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_QUEUED})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_GATEWAY_STARTING})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_PROGRESS})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_READING_DATA})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_PRUNING_DATA})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_SUCCESS, "web_result_url" => illustrate_url})).ordered
          
          # stub launchy
          mock(Launchy).open(illustrate_url) {Thread.new {}}
                    
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("illustrate my_script my_alias --polling_interval 0.05", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting illustrate... started

\r\e[0KIllustrate status: QUEUED /\r\e[0KIllustrate status: GATEWAY_STARTING -\r\e[0KIllustrate status: PROGRESS \\\r\e[0KIllustrate status: READING_DATA |\r\e[0KIllustrate status: PRUNING_DATA /\r\e[0KIllustrate status: SUCCESS  

Results available at https://api.mortardata.com/illustrates/c571a8c7f76a4fd4a67c103d753e2dd5
Opening web browser to show results... done
STDOUT
        end
      end
      
      it "requests and reports on a failed illustrate" do
        with_git_initialized_project do |p|
          # stub api requests
          illustrate_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          
          error_message = "This is my error message\nWith multiple lines."
          line_number = 23
          column_number = 32
          error_type = 'PigError'
          
          mock(Mortar::Auth.api).post_illustrate("myproject", "my_script", "my_alias", is_a(String)) {Excon::Response.new(:body => {"illustrate_id" => illustrate_id})}
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_QUEUED})).ordered
          mock(Mortar::Auth.api).get_illustrate(illustrate_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status" => Mortar::API::Illustrate::STATUS_FAILURE, 
            "error_message" => error_message,
            "line_number" => line_number,
            "column_number" => column_number,
            "error_type" => error_type})).ordered

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("illustrate my_script my_alias --polling_interval 0.05", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting illustrate... started

\r\e[0KIllustrate status: QUEUED /\r\e[0KIllustrate status: FAILURE  

STDOUT
          stderr.should == <<-STDERR
 !    Illustrate failed with PigError at Line 23, Column 32:
 !    
 !    This is my error message
 !    With multiple lines.
STDERR
        end
      end
    end
  end
end
