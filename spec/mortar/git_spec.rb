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
require "mortar/git"

module Mortar
  describe Git do
    
    before do
      @git = Mortar::Git::Git.new
    end
    
    context "has_git?" do
      it "returns false with no git installed" do
        mock(@git).run_cmd("git --version").returns("-bash: git: command not found")
        @git.has_git?.should be_false
      end

      it "returns false with unsupported git version" do
        mock(@git).run_cmd("git --version").returns("git version 1.7.6")
        @git.has_git?.should be_false
      end

      it "returns false with unsupported git version" do
        @git.has_git?.should be_true
      end

    end
    
    context "has_any_commits" do
      
      it "finds no commits on a blank project" do
        with_blank_project do |p|
          @git.has_commits?.should be_false
        end
      end
      
      it "finds commits when a project has them" do
        with_git_initialized_project do |p|
          @git.has_commits?.should be_true
        end
      end
    end
    
    context "git-rev" do
      it "looks up a revision" do
        with_git_initialized_project do |p|
          @git.git_ref("master").nil?.should be_false
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
      
      it "raises error on no .git file" do
        with_no_git_directory do
          lambda {@git.git("--version") }.should raise_error(Mortar::Git::GitError)
        end
      end
      
      it "does not raise error on no .git file with check disabled" do
        with_no_git_directory do
          lambda {@git.git("--version", true, false) }.should_not raise_error(Mortar::Git::GitError)
        end
      end
            
    end
    
    context "working directory" do
      it "finds clean and dirty working directories" do
        with_git_initialized_project do |p|
          @git.is_clean_working_directory?.should be_true
          write_file(File.join(p.root_path, "new_file.txt"))
          @git.is_clean_working_directory?.should be_false
        end
      end
    end
    
    context "untracked_files" do
      it "does not find ignored files" do
        with_git_initialized_project do |p|
          write_file(File.join(p.root_path, ".gitignore"), "tmp\n")
          write_file(File.join(p.root_path, "tmp", "ignored_file.txt"), "some text")
          write_file(File.join(p.root_path, "included_file.txt"), "some text")
          untracked_files = @git.untracked_files
          untracked_files.include?(".gitignore").should be_true
          untracked_files.include?("included_file.txt").should be_true
          untracked_files.include?("tmp/ignored_file.txt").should be_false
        end
      end
    end
    
    context "stash" do
      context "did_stash_changes" do
        it "finds that no changes were stashed" do
          with_git_initialized_project do |p|
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
          with_git_initialized_project do |p|
            @git.stash_working_dir("my_description").should be_false
          end
        end
        
        it "stashes an added file" do
          with_git_initialized_project do |p|
            git_add_file(@git, p)
            @git.is_clean_working_directory?.should be_false
            
            # stash
            @git.stash_working_dir("my_description").should be_true
            @git.is_clean_working_directory?.should be_true
          end
        end
        
        it "stashes an untracked file" do
          with_git_initialized_project do |p|
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
        with_git_initialized_project do |p|
          @git.current_branch.should == "master"
        end
      end
      
      it "fetches current branch with multiple branches" do
        with_git_initialized_project do |p|
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
      
      it "deletes a branch" do
        with_git_initialized_project do |p|
          new_branch_name = "new_branch_to_delete"
          @git.current_branch.should == "master"
          @git.git("checkout -b #{new_branch_name}")
          @git.branches.include?(new_branch_name).should be_true
          @git.git("checkout master")
          @git.branch_delete(new_branch_name)
          @git.branches.include?(new_branch_name).should be_false
          @git.current_branch.should == "master"
        end
      end
    end
    
    context "remotes" do
      it "handles when no remotes are defined" do
        with_git_initialized_project do |p|
          @git.git("remote rm mortar")
          @git.remotes("mortarcode").empty?.should be_true
        end
      end
      
      it "finds a single remote" do
        with_git_initialized_project do |p|
          remotes = @git.remotes("mortarcode-dev")
          remotes["mortar"].should == p.name
        end
      end
      
    end
    
    context "status" do
      it "detects conflicts" do
        with_git_initialized_project do |p|
          
          @git.is_clean_working_directory?.should be_true
          @git.has_conflicts?.should be_false
          git_create_conflict(@git, p)
          @git.is_clean_working_directory?.should be_false
          @git.has_conflicts?.should be_true
        end
      end
      
      it "detects no conflicts" do
        with_git_initialized_project do |p|
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
         with_git_initialized_project do |p|
           git_create_conflict(@git, p)
           lambda { @git.create_snapshot_branch }.should raise_error(Mortar::Git::GitError)
         end
      end
      
      it "creates a snapshot branch for a clean working directory" do
        with_git_initialized_project do |p|
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
      it "creates a snapshot branch for an added file" do
        with_git_initialized_project do |p|
          git_add_file(@git, p)
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
      it "creates a snapshot branch for an untracked file" do
        with_git_initialized_project do |p|
          git_create_untracked_file(p)
          starting_status = @git.status
          snapshot_branch = @git.create_snapshot_branch
          post_validate_git_snapshot(@git, starting_status, snapshot_branch)
        end
      end
      
    end
    
    context "clone" do
      it "clones repo successfully" do
        with_no_git_directory do
          File.directory?("rollup").should be_false
          @git.clone("git@github.com:mortarcode-dev/4fbbd83cce875be8a4000000_rollup", "rollup")
          File.directory?("rollup").should be_true
          Dir.chdir("rollup")
          lambda { @git.git("--version") }.should_not raise_error
        end
      end
      
    end
  end
end
