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
