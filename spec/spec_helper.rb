$stdin = File.new("/dev/null")

require "rubygems"
require "vendor/mortar/uuid"

require "excon"
Excon.defaults[:mock] = true

# ensure these are around for errors
# as their require is generally deferred
require "mortar-api-ruby"

require "mortar/cli"
require "rspec"
require "rr"
require "fakefs/safe"
require 'tmpdir'

def execute(command_line, project=nil, git=nil)

  args = command_line.split(" ")
  command = args.shift

  Mortar::Command.load
  object, method = Mortar::Command.prepare_run(command, args)

  # stub the project
  if project
    any_instance_of(Mortar::Command::Base) do |base|
      stub(base).project.returns(project)
    end
  end
  
  # stub git
  if git
    # stub out any operations that affect remote resources
    stub(git).push
    
    any_instance_of(Mortar::Command::Base) do |base|
      stub(base).git.returns(git)
    end
  end

  original_stdin, original_stderr, original_stdout = $stdin, $stderr, $stdout

  $stdin  = captured_stdin  = StringIO.new
  $stderr = captured_stderr = StringIO.new
  $stdout = captured_stdout = StringIO.new

  begin
    object.send(method)
  rescue SystemExit
  ensure
    $stdin, $stderr, $stdout = original_stdin, original_stderr, original_stdout
    Mortar::Command.current_command = nil
  end

  [captured_stderr.string, captured_stdout.string]
end

def any_instance_of(klass, &block)
  any_instance_of(klass, &block)
end

def run(command_line)
  capture_stdout do
    begin
      Mortar::CLI.start(*command_line.split(" "))
    rescue SystemExit
    end
  end
end

alias mortar run

def capture_stderr(&block)
  original_stderr = $stderr
  $stderr = captured_stderr = StringIO.new
  begin
    yield
  ensure
    $stderr = original_stderr
  end
  captured_stderr.string
end

def capture_stdout(&block)
  original_stdout = $stdout
  $stdout = captured_stdout = StringIO.new
  begin
    yield
  ensure
    $stdout = original_stdout
  end
  captured_stdout.string
end

def fail_command(message)
  raise_error(Mortar::Command::CommandFailed, message)
end

def stub_core
  @stubbed_core ||= begin
    stubbed_core = nil
    stub(Mortar::Auth).user.returns("email@example.com")
    stub(Mortar::Auth).password.returns("pass")
    stubbed_core
  end
end

def with_no_git_directory(&block)
  starting_dir = Dir.pwd
  sandbox = File.join(Dir.tmpdir, "mortar", Mortar::UUID.create_random.to_s)
  FileUtils.mkdir_p(sandbox)
  Dir.chdir(sandbox)
  
  begin
    block.call()
  ensure
    # return to the original starting dir,
    # if one is defined.  If using FakeFS, it will not
    # be defined
    if starting_dir && (! starting_dir.empty?)
      Dir.chdir(starting_dir)
    end

    FileUtils.rm_rf(sandbox)
  end
end

def with_blank_project(&block)
  # setup a sandbox directory
  starting_dir = Dir.pwd
  sandbox = File.join(Dir.tmpdir, "mortar", Mortar::UUID.create_random.to_s)
  FileUtils.mkdir_p(sandbox)
  
  # setup project directory
  project_name = "myproject"
  project_path = File.join(sandbox, project_name)
  FileUtils.mkdir_p(project_path)
  
  # setup project subdirectories
  FileUtils.mkdir_p(File.join(project_path, "datasets"))
  FileUtils.mkdir_p(File.join(project_path, "pigscripts"))

  Dir.chdir(project_path)
  
  # initialize git repo
  `git init`
  
  project = Mortar::Project::Project.new(project_name, project_path, nil)
  
  begin
    block.call(project)
  ensure
    # return to the original starting dir,
    # if one is defined.  If using FakeFS, it will not
    # be defined
    if starting_dir && (! starting_dir.empty?)
      Dir.chdir(starting_dir)
    end

    FileUtils.rm_rf(sandbox)
  end
end

def with_git_initialized_project(&block)
  # wrap block in a proc that does a commit
  commit_proc = Proc.new do |project|
    write_file(File.join(project.root_path, "README.txt"), "Some README text")
    remote = "mortar"
    `git add README.txt`
    `git commit -a -m "First commit"`
    `git remote add #{remote} git@github.com:mortarcode/4dbbd83cae8d5bf8a4000000_#{project.name}.git`
    project.remote = remote
    block.call(project)
  end
  
  with_blank_project(&commit_proc)
end

def write_file(path, contents="")
  FileUtils.mkdir_p File.dirname(path)
  File.open(path, 'w') {|f| f.write(contents)}
end

def git_create_conflict(git, project)
  filename = "conflict_file.txt"
  
  # add to master
  git.git("checkout master")
  write_file(File.join(project.root_path, filename), Mortar::UUID.create_random.to_s)
  git.add(filename)
  git.git("commit -a -m \"initial\"")
  
  # checkin change on branch
  git.git("checkout -b conflict_branch")
  write_file(File.join(project.root_path, filename), Mortar::UUID.create_random.to_s)
  git.add(filename)
  git.git("commit -a -m \"conflict from branch\"")
  
  # checkin change on master
  git.git("checkout master")
  write_file(File.join(project.root_path, filename), Mortar::UUID.create_random.to_s)
  git.add(filename)
  git.git("commit -a -m \"conflict from master\"")
  
  # merge
  git.git("merge conflict_branch", check_success=false)
  
  filename
end


def git_add_file(git, project)
  # add a new file
  added_file = "added_file.txt"
  write_file(File.join(project.root_path, added_file))
  git.add(added_file)
  added_file
end

def git_create_untracked_file(project)
  # add an untracked file
  untracked_file = "untracked_file.txt"
  write_file(File.join(project.root_path, untracked_file))
  untracked_file
end

def post_validate_git_snapshot(git, starting_status, snapshot_branch)
  snapshot_branch.should_not be_nil
  snapshot_branch.should_not == "master"
  git.current_branch.should == "master"
  git.status.should == starting_status
  git.has_conflicts?.should be_false
  
  # ensure the snapshot branch exists
  git.git("branch").include?(snapshot_branch).should be_true
end

require "mortar/helpers"
module Mortar::Helpers
  @home_directory = Dir.mktmpdir
  undef_method :home_directory
  def home_directory
    @home_directory
  end
end

require "support/display_message_matcher"

RSpec.configure do |config|
  config.mock_with :rr
  config.color_enabled = true
  config.include DisplayMessageMatcher
  config.before { Mortar::Helpers.error_with_failure = false }
  config.after { RR.verify; RR.reset }
end

