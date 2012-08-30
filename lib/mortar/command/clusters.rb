require "mortar/command/base"

## manage clusters
#
class Mortar::Command::Clusters < Mortar::Command::Base
    
  # clusters
  #
  # Display running and recently terminated clusters.
  #
  #Examples:
  #
  # $ mortar clusters
  # 
  #TBD
  #
  def index
    validate_arguments!
    
    clusters = api.get_clusters().body['clusters']
    if not clusters.empty?
      display_table(clusters,
      %w( cluster_id size status_description cluster_type_description start_timestamp duration),
      ['cluster_id', 'Size (# of Nodes)', 'Status', 'Type', 'Start Timestamp', 'Elapsed Time'])
    else
      display("There are currently no clusters running")
    end
    
  end
end
