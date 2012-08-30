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

require "vendor/mortar/uuid"
require "set"

module Mortar
  module Git
    
    class GitError < RuntimeError; end
    
    class Git
      
      #
      # core commands
      #
      
      def has_git?
        %x{ git --version }
        $?.success?
      end
      
      def has_dot_git?
        File.directory?(".git")
      end
      
      def git(args, check_success=true, check_git_directory=true)
        unless has_git?
          raise GitError, "git must be installed"
        end
        
        if check_git_directory && !has_dot_git?
          raise GitError, "No .git directory found"
        end
        
        flattened_args = [args].flatten.compact.join(" ")
        output = %x{ git #{flattened_args} 2>&1 }.strip
        success = $?.success?
        if check_success && (! success)
          raise GitError, "Error executing 'git #{flattened_args}':\n#{output}"
        end
        output
      end
    
      #    
      # snapshot
      #

      def create_snapshot_branch
        # TODO: handle Ctrl-C in the middle
        # TODO: can we do the equivalent of stash without changing the working directory
        unless has_commits?
          raise GitError, "No commits found in repository.  You must do an initial commit to initialize the repository."
        end
      
        starting_branch = current_branch
        snapshot_branch = "mortar-snapshot-#{Mortar::UUID.create_random.to_s}"
        did_stash_changes = stash_working_dir(snapshot_branch)
        begin
          # checkout a new branch
          git("checkout -b #{snapshot_branch}")
        
          if did_stash_changes
            # apply the topmost stash that we just created
            git("stash apply stash@{0}")
          end
        
          add_untracked_files()

          # commit the changes if there are any
          if ! is_clean_working_directory?
            git("commit -a -m \"mortar development snapshot commit\"")
          end
        
        ensure
        
          # return to the starting branch
          git("checkout #{starting_branch}")

          # rebuild the original state of the working set
          if did_stash_changes
            git("stash pop stash@{0}")
          end
        end
      
        snapshot_branch
      end

      #    
      # add
      #    

      def add(path)
        git("add #{path}")
      end
      
      def add_untracked_files
        untracked_files.each do |untracked_file|
          add untracked_file
        end
      end

      #
      # branch
      #
      
      def branches
        git("branch")
      end
      
      def current_branch
        branches.split("\n").each do |branch_listing|
        
          # current branch will be the one that starts with *, e.g.
          #   not_my_current_branch
          # * my_current_branch
          if branch_listing =~ /^\*\s(\S*)/
            return $1
          end
        end
        raise GitError, "Unable to find current branch in list #{branches}"
      end
      
      def branch_delete(branch_name)
        git("branch -D #{branch_name}")
      end

      #
      # push
      #
      
      def push(remote_name, ref)
        git("push #{remote_name} #{ref}")
      end


      #
      # remotes
      #

      def remotes(git_organization)
        # returns {git_remote_name => project_name}
        remotes = {}
        git("remote -v").split("\n").each do |remote|
          name, url, method = remote.split(/\s/)
          if url =~ /^git@([\w\d\.]+):#{git_organization}\/[a-zA-Z0-9]+_([\w\d-]+)\.git$$/
            remotes[name] = $2
          end
        end
        
        remotes
      end
      
      def remote_add(name, url)
        git("remote add #{name} #{url}")
      end

      #
      # rev-parse
      #
      def git_ref(refname)
        git("rev-parse --verify --quiet #{refname}")
      end

      #
      # stash
      #

      def stash_working_dir(stash_description)
        stash_output = git("stash save --include-untracked #{stash_description}")
        did_stash_changes? stash_output
      end
    
      def did_stash_changes?(stash_message)
        ! (stash_message.include? "No local changes to save")
      end

      #
      # status
      #
      
      def status
        git('status --porcelain')
      end
      
      
      def has_commits?
        # see http://stackoverflow.com/a/5492347
        %x{ git rev-parse --verify --quiet HEAD }
        $?.success?
      end

      def is_clean_working_directory?
        status.empty?
      end
    
      # see https://www.kernel.org/pub/software/scm/git/docs/git-status.html#_output
      GIT_STATUS_CODES__CONFLICT = Set.new ["DD", "AU", "UD", "UA", "DU", "AA", "UU"]
      def has_conflicts?
        def status_code(status_str)
          status_str[0,2]
        end
      
        status_codes = status.split("\n").collect{|s| status_code(s)}
        ! GIT_STATUS_CODES__CONFLICT.intersection(status_codes).empty?
      end
      
      def untracked_files
        git("ls-files -o --exclude-standard").split("\n")
      end
      
      #
      # clone
      #
      def clone(git_url, path="")
        git("clone %s \"%s\"" % [git_url, path], true, false)
      end
    end
  end
end