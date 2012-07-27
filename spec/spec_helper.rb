$stdin = File.new("/dev/null")

require "rubygems"

require "excon"
Excon.defaults[:mock] = true

# ensure these are around for errors
# as their require is generally deferred
#require "mortar-api"
require "rest_client"

require "mortar/cli"
require "rspec"
require "rr"
require "fakefs/safe"
require 'tmpdir'
require "webmock/rspec"

def execute(command_line, project=nil)
  extend RR::Adapters::RRMethods

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
  extend RR::Adapters::RRMethods
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
    any_instance_of(Mortar::Client) do |core|
      stubbed_core = stub(core)
    end
    stub(Mortar::Auth).user.returns("email@example.com")
    stub(Mortar::Auth).password.returns("pass")
    stub(Mortar::Client).auth.returns("apikey01")
    stubbed_core
  end
end

def with_blank_project(&block)
  # setup a sandbox directory
  sandbox = File.join(Dir.tmpdir, "mortar", Process.pid.to_s)
  FileUtils.mkdir_p(sandbox)
  
  # setup project directory
  project_name = "myproject"
  project_path = File.join(sandbox, project_name)
  FileUtils.mkdir_p(project_path)
  
  # setup project subdirectories
  FileUtils.mkdir_p(File.join(project_path, "datasets"))
  FileUtils.mkdir_p(File.join(project_path, "pigscripts"))

  Dir.chdir(project_path)
  
  project = Mortar::Project::Project.new(project_name, project_path)
  
  block.call(project)

  FileUtils.rm_rf(sandbox)
end

def write_file(path, contents="")
  FileUtils.mkdir_p File.dirname(path)
  File.open(path, 'w') {|f| f.write(contents)}
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
  config.color_enabled = true
  config.include DisplayMessageMatcher
  config.order = 'rand'
  config.before { Mortar::Helpers.error_with_failure = false }
  config.after { RR.reset }
end

