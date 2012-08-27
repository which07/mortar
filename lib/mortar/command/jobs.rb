require "mortar/command/base"
require "mortar/snapshot"

# manage pig scripts
#
class Mortar::Command::Jobs < Mortar::Command::Base

  include Mortar::Snapshot

  # jobs
  #
  # Show recent and running jobs.
  #
  # Examples:
  #
  # $ mortar jobs
  # 
  # TBD
  #
  def index
    raise NotImplementedError, "FIXME implement me"
    # call API for running jobs
    
    # emit them to the console
  end
    
  # jobs:run PIGSCRIPT
  #
  # Run a job on a Mortar Hadoop cluster.
  #
  # -c, --clusterid CLUSTERID   # Run job on an existing cluster.  Default: true.
  # -s, --clustersize NUMNODES  # Run job on a new cluster, with NUM_NODES nodes.
  # -k, --keepalive             # Keep this cluster running after the job finishes, to be used for future jobs.  Default: false.
  # -p, --parameter NAME=VALUE  # Set a pig parameter value in your script.
  #
  #Examples:
  #
  # $ mortar jobs:run
  # 
  # TBD
  #
  def run
    # arguemnts
    pigscript_name = shift_argument
    unless pigscript_name
      error("Usage: mortar jobs:run PIGSCRIPT\nMust specify PIGSCRIPT.")
    end
    validate_arguments!

    unless options[:clusterid] || options[:clustersize]
      error("Please provide either the --clustersize option to run job on a new cluster, or --clusterid to run on an existing one.")
    end
      
    if options[:clusterid]
      [:clustersize, :keepalive].each do |opt|
        unless options[opt].nil?
          error("Option #{opt.to_s} cannot be set when running a job on an existing cluster (with --clusterid option)")
        end
      end
    end
        
    validate_git_based_project!
    pigscript = validate_pigscript!(pigscript_name)
    git_ref = create_and_push_snapshot_branch(git, project)
    
    # post job to API
    job_id = action("Requesting job execution") do
      if options[:clustersize]
        cluster_size = options[:clustersize].to_i
        keepalive = options[:keepalive] || false
        api.post_job_new_cluster(project.name, pigscript.name, git_ref, cluster_size, 
          :parameters => pig_parameters,
          :keepalive => keepalive).body["job_id"]
      else
        cluster_id = options[:clusterid]
        api.post_job_existing_cluster(project.name, pigscript.name, git_ref, cluster_id,
          :parameters => pig_parameters).body["job_id"]
      end
    end
    display("job_id: #{job_id}")
    display
    display("To check job status, run:\n\n  mortar jobs:status #{job_id}")
    display
  end
  
  alias_command "run", "jobs:run"
  

  # jobs:status JOB_ID
  #
  # Check the status of a job.
  #
  #Examples:
  #
  # $ mortar jobs:status 84f3c86f20034ed4bf5e359120a47f5a
  #
  # TBD
  def status
    job_id = shift_argument
    unless job_id
      error("Usage: mortar jobs:status JOB_ID\nMust specify JOB_ID.")
    end
    
    job_status = api.get_job(job_id).body

    job_display_entries = {
      "status" => job_status["status"],
      "progress" => "#{job_status["progress"]}%",
      "cluster_id" => job_status["cluster_id"],
      "job submitted at" => job_status["start_timestamp"],
      "job began running at" => job_status["running_timestamp"],
      "job finished at" => job_status["stop_timestamp"],
      "job running for" => job_status["duration"],
      "job run with parameters" => job_status["parameters"],
      "error" => job_status["error"]
    }
    
    unless job_status["error"].nil? || job_status["error"]["message"].nil?
      error_context = get_error_message_context(job_status["error"]["message"])
      unless error_context == ""
        job_status["error"]["help"] = error_context
      end
    end
    
    if job_status["num_hadoop_jobs"] && job_status["num_hadoop_jobs_succeeded"]
      job_display_entries["hadoop jobs complete"] = "#{job_status["num_hadoop_jobs_succeeded"]} / #{job_status["num_hadoop_jobs"]}"
    end
    
    styled_header("#{job_status["project_name"]}: #{job_status["pigscript_name"]} (job_id: #{job_status["job_id"]})")
    styled_hash(job_display_entries)
  end
  
  # jobs:stop JOB_ID
  #
  # Stop a running job.
  #
  #Examples:
  #
  # $ mortar jobs:stop 84f3c86f20034ed4bf5e359120a47f5a
  #
  # TBD
  def stop
    raise NotImplementedError, "FIXME implement me"
  end
  
  alias_command "stop", "jobs:run"
  
end
