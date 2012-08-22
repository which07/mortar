require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/jobs'
require 'mortar/api/jobs'

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
          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_size = 5
          keepalive = true

          mock(Mortar::Auth.api).post_job_new_cluster("myproject", "my_script", is_a(String), cluster_size, :parameters => [{"name" => "FIRST_PARAM", "value" => "FOO"}, {"name" => "SECOND_PARAM", "value" => "BAR"}], :keepalive => true) {Excon::Response.new(:body => {"job_id" => job_id})}

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

      it "runs a job on an existing cluster" do
        with_git_initialized_project do |p|
          # stub api requests
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          cluster_id = "e2790e7e8c7d48e39157238d58191346"

          mock(Mortar::Auth.api).post_job_existing_cluster("myproject", "my_script", is_a(String), cluster_id, :parameters => []) {Excon::Response.new(:body => {"job_id" => job_id})}

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
    
    context("status") do
      it "gets status for a running job" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status = Mortar::API::Jobs::STATUS_RUNNING
          progress = 55
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}
          
          mock(Mortar::Auth.api).get_job(job_id) {Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status" => status,
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 2,
            "parameters" => parameters
            })}
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5", p, @git)
          stdout.should == <<-STDOUT
=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
hadoop jobs complete:    2 / 4
job began running at:    2012-02-28T03:41:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
progress:                55%
status:                  running
STDOUT
        end
      end

      it "gets status for a error job" do
        with_git_initialized_project do |p|
          job_id = "c571a8c7f76a4fd4a67c103d753e2dd5"
          pigscript_name = "my_script"
          project_name = "myproject"
          status = Mortar::API::Jobs::STATUS_EXECUTION_ERROR
          progress = 55
          cluster_id = "e2790e7e8c7d48e39157238d58191346"
          start_timestamp = "2012-02-28T03:35:42.831000+00:00"
          running_timestamp = "2012-02-28T03:41:52.613000+00:00"
          stop_timestamp = "2012-02-28T03:45:52.613000+00:00"
          parameters = {"my_param_1" => "value1", "MY_PARAM_2" => "3"}
          error = {"message" => "An error occurred and here's some more info",
                   "type" => "RuntimeError",
                   "line_number" => 43,
                   "column_number" => 34}
          mock(Mortar::Auth.api).get_job(job_id) {Excon::Response.new(:body => {"job_id" => job_id,
            "pigscript_name" => pigscript_name,
            "project_name" => project_name,
            "status" => status,
            "progress" => progress,
            "cluster_id" => cluster_id,
            "start_timestamp" => start_timestamp,
            "running_timestamp" => running_timestamp,
            "stop_timestamp" => stop_timestamp,
            "duration" => "6 mins",
            "num_hadoop_jobs" => 4,
            "num_hadoop_jobs_succeeded" => 2,
            "parameters" => parameters,
            "error" => error
            })}
          stderr, stdout = execute("jobs:status c571a8c7f76a4fd4a67c103d753e2dd5", p, @git)
          stdout.should == <<-STDOUT
=== myproject: my_script (job_id: c571a8c7f76a4fd4a67c103d753e2dd5)
cluster_id:              e2790e7e8c7d48e39157238d58191346
error:                   
  column_number:   34
  line_number:     43
  message:         An error occurred and here's some more info
  type:            RuntimeError
hadoop jobs complete:    2 / 4
job began running at:    2012-02-28T03:41:52.613000+00:00
job finished at:         2012-02-28T03:45:52.613000+00:00
job run with parameters: 
  MY_PARAM_2:   3
  my_param_1:   value1
job running for:         6 mins
job submitted at:        2012-02-28T03:35:42.831000+00:00
progress:                55%
status:                  execution_error
STDOUT
        end
      end
      
      
    end

    context("stop") do
    end
    
  end
end
