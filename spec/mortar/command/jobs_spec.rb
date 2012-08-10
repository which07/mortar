require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/jobs'

module Mortar::Command
  describe Jobs do
    
    before(:each) do
      stub_core      
      @git = Mortar::Git::Git.new
    end
        
    context("index") do
    end
    
    context("run") do
      it "runs a job on a new cluster" do
        with_git_initialized_project do |p|
          # stub git
          mock(@git).push

          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5
          keepalive = true

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, :parameters => {"FIRST_PARAM" => "FOO", "SECOND_PARAM" => "BAR"}, :keepalive => true) {Excon::Response.new(:body => {"job_id" => job_id})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script --clustersize 5 --keepalive -p FIRST_PARAM=FOO -p SECOND_PARAM=BAR", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

To check job status, run:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5

STDOUT
        end
      end

      it "runs a job on a new cluster" do
        with_git_initialized_project do |p|
          # stub git
          mock(@git).push

          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_id = "e2790e7e8c7d48e39157238d58191346"

          mock(Mortar::Auth.api).post_job_existing_cluster("myproject", "my_script", is_a(String), cluster_id, :parameters => {}) {Excon::Response.new(:body => {"job_id" => job_id})}

          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("jobs:run my_script --clusterid e2790e7e8c7d48e39157238d58191346", p, @git)
          stdout.should == <<-STDOUT
Taking code snapshot... done
Sending code snapshot to Mortar... done
Requesting job execution... done
job_id: c571a8c7f76a4fd4a67c103d753e2dd5

To check job status, run:

  mortar jobs:status c571a8c7f76a4fd4a67c103d753e2dd5

STDOUT
        end
      end
    end

    context("stop") do
    end
    
  end
end
