require "spec_helper"
require "mortar/git"

module Mortar
  describe Git do
    
    before do
      @git = Mortar::Git::Git.new
    end
    
    
    context "has_any_commits" do
      
      it "finds no commits on a blank project" do
        with_blank_project do |p|
          @git.has_commits?.should be_false
        end
      end
      
      it "finds commits when a project has them" do
        with_first_commit_project do |p|
          @git.has_commits?.should be_true
        end
      end
    end
    
    context "git" do
      
      it "raises on git failure" do
        with_blank_project do |p|
          lambda { @git.git("not_a_git_command") }.should raise_error(Mortar::Git::GitError)
        end
      end

      it "does not raise on git success" do
        with_blank_project do |p|
          lambda { @git.git("--version") }.should_not raise_error
        end
      end
      
    end
    
    context "working directory" do
      it "finds clean and dirty working directories" do
        with_first_commit_project do |p|
          @git.is_clean_working_directory?.should be_true
          write_file(File.join(p.root_path, "new_file.txt"))
          @git.is_clean_working_directory?.should be_false
        end
      end
    end
    
    context "stash" do
      context "did_stash_changes" do
        it "finds that no changes were stashed" do
          with_first_commit_project do |p|
            @git.did_stash_changes?("No local changes to save").should be_false
          end
        end
        
        it "finds that changes were stashed" do
          stash_message = <<-STASH
Saved working directory and index state On master: myproject
HEAD is now at f3d74e8 Add an example
STASH
          @git.did_stash_changes?(stash_message).should be_true
        end
      end
      
      context "stash_working_dir" do
        it "does not error on a clean working directory" do
          with_first_commit_project do |p|
            @git.stash_working_dir("my_description").should be_false
          end
        end
        
        it "stashes an added file" do
          with_first_commit_project do |p|
            git_add_file(@git, p)
            @git.is_clean_working_directory?.should be_false
            
            # stash
            @git.stash_working_dir("my_description").should be_true
            @git.is_clean_working_directory?.should be_true
          end
        end
        
        it "stashes an untracked file" do
          with_first_commit_project do |p|
            git_create_untracked_file(p)
            @git.is_clean_working_directory?.should be_false
            
            # stash
            @git.stash_working_dir("my_description").should be_true
            @git.is_clean_working_directory?.should be_true
          end
        end
      end
    end
    
    context "branch" do
      
      it "fetches current branch with one branch" do
        with_first_commit_project do |p|
          @git.current_branch.should == "master"
        end
      end
      
      it "fetches current branch with multiple branches" do
        with_first_commit_project do |p|
          @git.git("checkout -b branch_01")
          @git.git("checkout -b branch_02")
          @git.current_branch.should == "branch_02"
        end
      end
      
      it "raises if no branches found" do
        with_blank_project do |p|
          lambda { @git.current_branch }.should raise_error(Mortar::Git::GitError)
        end
      end
    end
    
    context "status" do
      it "detects conflicts" do
        with_first_commit_project do |p|
          
          @git.is_clean_working_directory?.should be_true
          @git.has_conflicts?.should be_false
          git_create_conflict(@git, p)
          @git.is_clean_working_directory?.should be_false
          @git.has_conflicts?.should be_true
        end
      end
      
      it "detects no conflicts" do
        with_first_commit_project do |p|
          @git.has_conflicts?.should be_false
        end
      end
    end
    
    context "snapshot" do
      it "raises when no commits are found in the repo" do
        with_blank_project do |p|
          lambda { @git.create_snapshot_branch }.should raise_error(Mortar::Git::GitError)
        end
      end
      
      it "raises when a conflict exists in working directory" do
         with_first_commit_project do |p|
           git_create_conflict(@git, p)
           lambda { @git.create_snapshot_branch }.should raise_error(Mortar::Git::GitError)
         end
      end
      
      it "creates a snapshot branch for a clean working directory" do
        with_first_commit_project do |p|
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
      it "creates a snapshot branch for an added file" do
        with_first_commit_project do |p|
          git_add_file(@git, p)
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
      it "creates a snapshot branch for an untracked file" do
        with_first_commit_project do |p|
          git_create_untracked_file(p)
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
    end
  end
end
