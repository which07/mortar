require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/projects'
require 'launchy'
require "mortar/api"


module Mortar::Command
  describe Projects do
    
    before(:each) do
      stub_core      
      @git = Mortar::Git::Git.new
    end
    
    project1 = {'name' => "Project1",
                'status' => Mortar::API::Projects::STATUS_ACTIVE,
                'github_repo_name' => "Project1"}
    project2 = {'name' => "Project2",
                'status' => Mortar::API::Projects::STATUS_ACTIVE,
                'github_repo_name' => "Project2"}
        
    context("index") do
      
      it "shows appropriate message when user has no projects" do
        mock(Mortar::Auth.api).get_projects().returns(Excon::Response.new(:body => {"projects" => []}))
        
        stderr, stdout = execute("projects")
        stdout.should == <<-STDOUT
You have no projects.
STDOUT
      end
      
      it "shows appropriate message when user has multiple projects" do
        mock(Mortar::Auth.api).get_projects().returns(Excon::Response.new(:body => {"projects" => [project1, project2]}))
        
        stderr, stdout = execute("projects")
        stdout.should == <<-STDOUT
=== projects
Project1
Project2

STDOUT
      end
    end
    
    context("create") do
      
      it "show appropriate error message when user doesn't include project name" do
        stderr, stdout = execute("projects:create")
        stderr.should == <<-STDERR
 !    Usage: mortar projects:create PROJECT
 !    Must specify PROJECT.
STDERR
      end

      it "try to create project in directory that doesn't have a git repository" do
        with_no_git_directory do
          stderr, stdout = execute("projects:create some_new_project")
          stderr.should == <<-STDERR
 !    Can only create a mortar project for an existing git project.  Please run:
 !    
 !    git init
 !    git commit -a -m "first commit"
 !    
 !    to initialize your project in git.
STDERR
        end
      end
      
      it "show appropriate error message when user tries to create a project inside of an existing project" do
         with_git_initialized_project do |p|           
           stderr, stdout = execute("projects:create some_new_project", nil, @git)
           stderr.should == <<-STDERR
 !    Currently in project: myproject.  You can not create a new project inside of an existing mortar project.
STDERR
         end
      end
      
      it "create a new project successfully" do
        project_id = "1234abcd1234abcd1234"
        mock(Mortar::Auth.api).post_project("some_new_project") {Excon::Response.new(:body => {"project_id" => project_id})}
        mock(Mortar::Auth.api).get_project(project_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Projects::STATUS_PENDING})).ordered
        mock(Mortar::Auth.api).get_project(project_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Projects::STATUS_CREATING})).ordered
        mock(Mortar::Auth.api).get_project(project_id).returns(Excon::Response.new(:body => {"status" => Mortar::API::Projects::STATUS_ACTIVE})).ordered

        stderr, stdout = execute("projects:create some_new_project")
        stdout.should == <<-STDOUT
Creating project... started
 ... PENDING
 ... CREATING
 ... ACTIVE
STDOUT
      end
      
    end
    
    
    context("clone") do
      
      it "shows appropriate error message when user doesn't include project name" do
        stderr, stdout = execute("projects:clone")
        stderr.should == <<-STDERR
 !    Usage: mortar projects:clone PROJECT
 !    Must specify PROJECT.
STDERR
      end
      
      it "shows appropriate error message when user tries to clone non-existent project" do
        mock(Mortar::Auth.api).get_projects().returns(Excon::Response.new(:body => {"projects" => [project1, project2]}))
        
        stderr, stdout = execute('projects:clone sillyProjectName')
        stderr.should == <<-STDERR
 !    Invalid project name: sillyProjectName
STDERR
      end
      
      it "calls git clone when existing project is cloned" do
        mock(Mortar::Auth.api).get_projects().returns(Excon::Response.new(:body => {"projects" => [project1, project2]}))
        mock(@git).clone(::GIT_HOST, ::GIT_ORGANIZATION, project1['github_repo_name'], project1['name'])
        stderr, stdout = execute('projects:clone Project1', nil, @git)
      end
      
    end
  end
end