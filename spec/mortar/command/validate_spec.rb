require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/validate'
require 'mortar/api/validate'
require 'launchy'

module Mortar::Command
  describe Validate do
    
    before(:each) do
      stub_core      
      @git = Mortar::Git::Git.new
    end
        
    context("index") do
      
      it "errors when no remote exists in the project" do
        with_git_initialized_project do |p|
          @git.git('remote rm mortar')
          p.remote = nil
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("validate my_script", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find git remote for project myproject
STDERR
        end
      end

      it "errors when requested pigscript cannot be found" do
        with_git_initialized_project do |p|
          stderr, stdout = execute("validate does_not_exist", p, @git)
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    No pigscripts found
 STDERR
        end
      end
      
      it "requests and reports on a successful validate" do
        with_git_initialized_project do |p|
          # stub api requests
          validate_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          parameters = ["name"=>"key", "value"=>"value" ]
          
          mock(Mortar::Auth.api).post_validate("myproject", "my_script", is_a(String), :parameters => parameters) {Excon::Response.new(:body => {"validate_id" => validate_id})}
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_QUEUED})).ordered
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_GATEWAY_STARTING})).ordered
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_PROGRESS})).ordered
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_SUCCESS})).ordered
                              
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("validate my_script --polling_interval 0.05 -p key=value", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting validate... started

\r\e[0KValidate status: QUEUED /\r\e[0KValidate status: GATEWAY_STARTING -\r\e[0KValidate status: PROGRESS \\\r\e[0KValidate status: SUCCESS  

Your script is valid.
STDOUT
        end
      end
      
      it "requests and reports on a failed validate" do
        with_git_initialized_project do |p|
          # stub api requests
          validate_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          
          error_message = "This is my error message\nWith multiple lines."
          line_number = 23
          column_number = 32
          error_type = 'PigError'
          
          mock(Mortar::Auth.api).post_validate("myproject", "my_script", is_a(String), :parameters => []) {Excon::Response.new(:body => {"validate_id" => validate_id})}
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_QUEUED})).ordered
          mock(Mortar::Auth.api).get_validate(validate_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Validate::STATUS_FAILURE, 
            "error_message" => error_message,
            "line_number" => line_number,
            "column_number" => column_number,
            "error_type" => error_type})).ordered

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("validate my_script --polling_interval 0.05", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Starting validate... started

\r\e[0KValidate status: QUEUED /\r\e[0KValidate status: FAILURE  

STDOUT
          stderr.should == <<-STDERR
 !    Validate failed with PigError at Line 23, Column 32:
 !    
 !    This is my error message
 !    With multiple lines.
STDERR
        end
      end
    end
  end
end
