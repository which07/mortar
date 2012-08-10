module Mortar
  module Snapshot

    extend self
    
    def create_and_push_snapshot_branch(git, project)
      # create / push a snapshot branch
      snapshot_branch = action("Taking code snapshot") do
        git.create_snapshot_branch()
      end

      git_ref = action("Sending code snapshot to Mortar") do
        # push the code
        git.push(project.remote, snapshot_branch)

        # grab the commit hash and clean out the branch from the local branches
        ref = git.git_ref(snapshot_branch)
        git.branch_delete(snapshot_branch)
        ref
      end
    end
  end
end