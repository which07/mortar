#
# Copyright 2012 Mortar Data Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require "mortar/command/base"
require "time"

# run and view status of pig jobs (run, status)
#
class Mortar::Command::Jobs < Mortar::Command::Base

  include Mortar::Git

  # jobs
  #
  # Show recent and running jobs.
  #
  # -l, --limit LIMITJOBS # Limit the number of jobs returned (defaults to 10)
  # -s, --skip SKIPJOBS   # Skip a certain amount of jobs (defaults to 0)
  #
  # Examples:
  #
  #     List the last 20 jobs:
  #          $ mortar jobs -l 20
  def index
    validate_arguments!

    options[:limit] ||= '10'
    options[:skip] ||= '0'
    jobs = api.get_jobs(options[:skip], options[:limit]).body['jobs']
    jobs.each do |job|
      if job['start_timestamp']
        job['start_timestamp'] = Time.parse(job['start_timestamp']).strftime('%A, %B %e, %Y, %l:%M %p')
      end
    end
    headers = [ 'job_id', 'script' , 'status' , 'start_date' , 'elapsed_time' , 'cluster_size' , 'cluster_id']
    columns = [ 'job_id', 'display_name', 'status_description', 'start_timestamp', 'duration', 'cluster_size', 'cluster_id']
    display_table(jobs, columns, headers)
  end
    
  # jobs:run PIGSCRIPT
  #
  # Run a job on a Mortar Hadoop cluster.
  #
  # -c, --clusterid CLUSTERID   # Run job on an existing cluster with ID of CLUSTERID (optional)
  # -s, --clustersize NUMNODES  # Run job on a new cluster, with NUMNODES nodes (optional; must be >= 2 if provided)
  # -1, --singlejobcluster      # Stop the cluster after job completes.  (Default: false—-cluster can be used for other jobs, and will shut down after 1 hour of inactivity)
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  # -f, --param-file PARAMFILE  # Load pig parameter values from a file.
  # -d, --donotnotify           # Don't send an email on job completion.  (Default: false--an email will be sent to you once the job completes)
  #
  #Examples:
  #
  #    Run the generate_regression_model_coefficients script on a 3 node cluster.
  #        $ mortar jobs:run generate_regression_model_coefficients --clustersize 3
  def run
    pigscript_name = shift_argument
    unless pigscript_name
      error("Usage: mortar jobs:run PIGSCRIPT\nMust specify PIGSCRIPT.")
    end
    validate_arguments!

    unless options[:clusterid] || options[:clustersize]
      clusters = api.get_clusters().body['clusters']

      largest_free_cluster = clusters.select{ |c| \
        c['running_jobs'].length == 0 && c['status_code'] == Mortar::API::Clusters::STATUS_RUNNING }.
        max_by{|c| c['size']}

      if largest_free_cluster.nil?
        options[:clustersize] = 2
        display("Defaulting to running job on new cluster of size 2")
      else
        options[:clusterid] = largest_free_cluster['cluster_id']
        display("Defaulting to running job on largest existing free cluster, id = " + 
                largest_free_cluster['cluster_id'] + ", size = " + largest_free_cluster['size'].to_s)
      end
    end
      
    if options[:clusterid]
      [:clustersize, :singlejobcluster].each do |opt|
        unless options[opt].nil?
          error("Option #{opt.to_s} cannot be set when running a job on an existing cluster (with --clusterid option)")
        end
      end
    end
 
    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)
    git_ref = git.create_and_push_snapshot_branch(project)
    notify_on_job_finish = ! options[:donotnotify]
    
    # post job to API
    response = action("Requesting job execution") do
      if options[:clustersize]
        cluster_size = options[:clustersize].to_i
        keepalive = ! options[:singlejobcluster]
        api.post_job_new_cluster(project.name, pigscript.name, git_ref, cluster_size, 
          :parameters => pig_parameters,
          :keepalive => keepalive,
          :notify_on_job_finish => notify_on_job_finish).body
      else
        cluster_id = options[:clusterid]
        api.post_job_existing_cluster(project.name, pigscript.name, git_ref, cluster_id,
          :parameters => pig_parameters,
          :notify_on_job_finish => notify_on_job_finish).body
      end
    end

    display("job_id: #{response['job_id']}")
    display
    display("Job status can be viewed on the web at:\n\n #{response['web_job_url']}")
    display
    display("Or by running:\n\n  mortar jobs:status #{response['job_id']} --poll")
    display
  end
  
  alias_command "run", "jobs:run"
  

  # jobs:status JOB_ID
  #
  # Check the status of a job.
  #
  # -p, --poll      # Poll the status of a job
  #
  def status
    job_id = shift_argument
    unless job_id
      error("Usage: mortar jobs:status JOB_ID\nMust specify JOB_ID.")
    end
    
    # Inner function to display the hash table when the job is complte
    def display_job_status(job_status)
      job_display_entries = {
        "status" => job_status["status_description"],
        "progress" => "#{job_status["progress"]}%",
        "cluster_id" => job_status["cluster_id"],
        "job submitted at" => job_status["start_timestamp"],
        "job began running at" => job_status["running_timestamp"],
        "job finished at" => job_status["stop_timestamp"],
        "job running for" => job_status["duration"],
        "job run with parameters" => job_status["parameters"],
      }

      
      unless job_status["error"].nil? || job_status["error"]["message"].nil?
        error_context = get_error_message_context(job_status["error"]["message"])
        unless error_context == ""
          job_status["error"]["help"] = error_context
        end
        job_status["error"].each_pair do |key, value|
          job_display_entries["error - #{key}"] = value
        end
      end
      
      if job_status["num_hadoop_jobs"] && job_status["num_hadoop_jobs_succeeded"]
        job_display_entries["hadoop jobs complete"] = 
          '%0.2f / %0.2f' % [job_status["num_hadoop_jobs_succeeded"], job_status["num_hadoop_jobs"]]
      end
      
      if job_status["outputs"] && job_status["outputs"].length > 0
        job_display_entries["outputs"] = Hash[job_status["outputs"].select{|o| o["alias"]}.collect do |output|
          output_hash = {}
          output_hash["location"] = output["location"] if output["location"]
          output_hash["records"] = output["records"] if output["records"]
          [output['alias'], output_hash]
        end]
      end
      
      styled_header("#{job_status["project_name"]}: #{job_status["pigscript_name"]} (job_id: #{job_status["job_id"]})")
      styled_hash(job_display_entries)
    end
    
    # If polling the status
    if options[:poll]
      ticking(polling_interval) do |ticks|
        job_status = api.get_job(job_id).body
        # If the job is complete exit and display the table normally 
        if Mortar::API::Jobs::STATUSES_COMPLETE.include?(job_status["status_code"] )
          redisplay("")
          display_job_status(job_status)
          break
        end

        # If the job is running show the progress bar
        if job_status["status_code"] == Mortar::API::Jobs::STATUS_RUNNING
          progressbar = "=" + ("=" * (job_status["progress"].to_i / 5)) + ">"

          if job_status["num_hadoop_jobs"] && job_status["num_hadoop_jobs_succeeded"]
            hadoop_jobs_ratio_complete = 
              '%0.2f / %0.2f' % [job_status["num_hadoop_jobs_succeeded"], job_status["num_hadoop_jobs"]]
          end

          printf("\r[#{spinner(ticks)}] Status: [%-22s] %s%% Complete (%s MapReduce jobs finished)", progressbar, job_status["progress"], hadoop_jobs_ratio_complete)

        # If the job is not complete, but not in the running state, just display its status
        else
          redisplay("[#{spinner(ticks)}] Status: #{job_status['status_description']}")
        end
      end
    # If not polling, get the job status and display the results
    else
      job_status = api.get_job(job_id).body
      display_job_status(job_status)
    end
  end

  # jobs:stop JOB_ID
  #
  # Stop a running job.
  #
  def stop
    job_id = shift_argument
    unless job_id
      error("Usage: mortar jobs:stop JOB_ID\nMust specify JOB_ID.")
    end

    response = api.stop_job(job_id).body  

    #TODO: jkarn - Once all servers have the additional message field we can remove this check.
    if response['message'].nil?
      display("Stopping job #{job_id}.")
    else
      display(response['message'])
    end
  end
end
