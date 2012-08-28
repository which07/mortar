require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/describe'
require 'mortar/api/describe'
require 'launchy'

module Mortar::Command
  describe Describe do
    
    before(:each) do
      stub_core      
      @git = Mortar::Git::Git.new
    end
        
    context("index") do
      
      it "errors when an alias is not provided" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("describe my_script", p)
          stderr.should == <<-STDERR
 !    Usage: mortar describe PIGSCRIPT ALIAS
 !    Must specify PIGSCRIPT and ALIAS.
STDERR
        end
      end

      it "errors when no remote exists in the project" do
        with_git_initialized_project do |p|
          @git.git('remote rm mortar')
          p.remote = nil
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("describe my_script my_alias", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find git remote for project myproject
STDERR
        end
      end

      it "errors when requested pigscript cannot be found" do
        with_git_initialized_project do |p|
          stderr, stdout = execute("describe does_not_exist my_alias", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    No pigscripts found
 STDERR
        end
      end
      
      it "requests and reports on a successful describe" do
        with_git_initialized_project do |p|
          # stub api requests
          describe_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          describe_url = "https://api.mortardata.com/describe/#{describe_id}"
          parameters = ["name"=>"key", "value"=>"value" ]
          
          mock(Mortar::Auth.api).post_describe("myproject", "my_script", "my_alias", is_a(String), :parameters => parameters) {Excon::Response.new(:body => {"describe_id" => describe_id})}
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_QUEUED, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_GATEWAY_STARTING, "status_description" => "Gateway starting"})).ordered
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_PROGRESS, "status_description" => "Starting pig"})).ordered
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_SUCCESS, "status_description" => "Success", "web_result_url" => describe_url})).ordered
          
          # stub launchy
          mock(Launchy).open(describe_url) {Thread.new {}}
                    
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("describe my_script my_alias --polling_interval 0.05 -p key=value", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting describe... done

\r\e[0KStatus: Pending... /\r\e[0KStatus: Gateway starting... -\r\e[0KStatus: Starting pig... \\\r\e[0KStatus: Success  

Results available at https://api.mortardata.com/describe/c571a8c7f76a4fd4a67c103d753e2dd5
Opening web browser to show results... done
STDOUT
        end
      end
      
      it "requests and reports on a failed describe" do
        with_git_initialized_project do |p|
          # stub api requests
          describe_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          
          error_message = "This is my error message\nWith multiple lines."
          line_number = 23
          column_number = 32
          error_type = 'PigError'
          
          mock(Mortar::Auth.api).post_describe("myproject", "my_script", "my_alias", is_a(String), :parameters => []) {Excon::Response.new(:body => {"describe_id" => describe_id})}
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_QUEUED, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_describe(describe_id, :exclude_result => true).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Describe::STATUS_FAILURE, "status_description" => "Failed",
            "error_message" => error_message,
            "line_number" => line_number,
            "column_number" => column_number,
            "error_type" => error_type})).ordered

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("describe my_script my_alias --polling_interval 0.05", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting describe... done

\r\e[0KStatus: Pending... /\r\e[0KStatus: Failed  

STDOUT
          stderr.should == <<-STDERR
 !    Describe failed with PigError at Line 23, Column 32:
 !    
 !    This is my error message
 !    With multiple lines.
STDERR
        end
      end
    end
  end
end
