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
    display_table(clusters,
      %w( cluster_id size status_description cluster_type_description start_timestamp duration),
      ['cluster_id', 'Size (# of Nodes)', 'Status', 'Type', 'Start Timestamp', 'Elapsed Time'])
  end
end
