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

require "spec_helper"
require "mortar/helpers"

module Mortar
  describe Snapshot do
    include Mortar::Helpers
    include Mortar::Snapshot

    before(:each) do
      @git = Mortar::Git::Git.new
    end
    
    it "create and push a snapshot to the remote repository" do
      with_git_initialized_project do |p|
        # stub git
        mock(@git).push("mortar", is_a(String))
        mock.proxy(@git).create_snapshot_branch
        
        stub(self).display
        
        initial_git_branches = @git.branches
        create_and_push_snapshot_branch(@git, p)
        
        # ensure that no additional branches are left behind
        @git.branches.should == initial_git_branches
      end
    end
    
  end
end
