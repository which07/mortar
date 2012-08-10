require "fileutils"
require "mortar/auth"
require "mortar/command"
require "mortar/project"
require "mortar/git"

class Mortar::Command::Base
  include Mortar::Helpers

  def self.namespace
    self.to_s.split("::").last.downcase
  end

  attr_reader :args
  attr_reader :options

  def initialize(args=[], options={})
    @args = args
    @options = options
  end

  def project
    unless @project
      project_name, project_dir, remote = 
      if options[:project].is_a?(String)
        [options[:project], nil, nil]
      elsif ENV.has_key?('MORTAR_PROJECT')
        [ENV['MORTAR_PROJECT'], nil, nil]
      elsif project_from_dir = extract_project_in_dir()
        [project_from_dir[0], Dir.pwd, project_from_dir[1]]
      else
        raise Mortar::Command::CommandFailed, "No project specified.\nRun this command from a project folder or specify which project to use with --project <project name>"
      end
      
      # if we only have a project name, look for the remote in the current dir
      unless remote
        if project_from_dir = extract_project_in_dir(project_name)
          project_dir = Dir.pwd
          remote = project_from_dir[1]
        end
      end
      
      @project = Mortar::Project::Project.new(project_name, project_dir, remote)
    end
    @project
  end
  
  def api
    Mortar::Auth.api
  end
  
  def git
    @git ||= Mortar::Git::Git.new
  end

protected

  def self.inherited(klass)
    unless klass == Mortar::Command::Base
      help = extract_help_from_caller(caller.first)

      Mortar::Command.register_namespace(
        :name => klass.namespace,
        :description => help.first
      )
    end
  end

  def self.method_added(method)
    return if self == Mortar::Command::Base
    return if private_method_defined?(method)
    return if protected_method_defined?(method)

    help = extract_help_from_caller(caller.first)
    resolved_method = (method.to_s == "index") ? nil : method.to_s
    command = [ self.namespace, resolved_method ].compact.join(":")
    banner = extract_banner(help) || command

    Mortar::Command.register_command(
      :klass       => self,
      :method      => method,
      :namespace   => self.namespace,
      :command     => command,
      :banner      => banner.strip,
      :help        => help.join("\n"),
      :summary     => extract_summary(help),
      :description => extract_description(help),
      :options     => extract_options(help)
    )
  end

  def self.alias_command(new, old)
    raise "no such command: #{old}" unless Mortar::Command.commands[old]
    Mortar::Command.command_aliases[new] = old
  end

  #
  # Parse the caller format and identify the file and line number as identified
  # in : http://www.ruby-doc.org/core/classes/Kernel.html#M001397.  This will
  # look for a colon followed by a digit as the delimiter.  The biggest
  # complication is windows paths, which have a color after the drive letter.
  # This regex will match paths as anything from the beginning to a colon
  # directly followed by a number (the line number).
  #
  # Examples of the caller format :
  # * c:/Ruby192/lib/.../lib/mortar/command/addons.rb:8:in `<module:Command>'
  # * c:/Ruby192/lib/.../mortar-2.0.1/lib/heroku/command/pg.rb:96:in `<class:Pg>'
  # * /Users/ph7/...../xray-1.1/lib/xray/thread_dump_signal_handler.rb:9
  #
  def self.extract_help_from_caller(line)
    # pull out of the caller the information for the file path and line number
    if line =~ /^(.+?):(\d+)/
      extract_help($1, $2)
    else
      raise("unable to extract help from caller: #{line}")
    end
  end

  def self.extract_help(file, line_number)
    buffer = []
    lines = Mortar::Command.files[file]

    (line_number.to_i-2).downto(0) do |i|
      line = lines[i]
      case line[0..0]
        when ""
        when "#"
          buffer.unshift(line[1..-1])
        else
          break
      end
    end

    buffer
  end

  def self.extract_banner(help)
    help.first
  end

  def self.extract_summary(help)
    extract_description(help).split("\n")[2].to_s.split("\n").first
  end

  def self.extract_description(help)
    help.reject do |line|
      line =~ /^\s+-(.+)#(.+)/
    end.join("\n")
  end

  def self.extract_options(help)
    help.select do |line|
      line =~ /^\s+-(.+)#(.+)/
    end.inject({}) do |hash, line|
      description = line.split("#", 2).last
      long  = line.match(/--([A-Za-z\- ]+)/)[1].strip
      short = line.match(/-([A-Za-z ])[ ,]/) && $1 && $1.strip
      hash.update(long.split(" ").first => { :desc => description, :short => short, :long => long })
    end
  end

  def current_command
    Mortar::Command.current_command
  end

  def extract_option(key)
    options[key.dup.gsub('-','').to_sym]
  end

  def invalid_arguments
    Mortar::Command.invalid_arguments
  end

  def shift_argument
    Mortar::Command.shift_argument
  end

  def validate_arguments!
    Mortar::Command.validate_arguments!
  end

  def validate_git_based_project!
    unless project.root_path
      error("#{current_command[:command]} must be run from the checked-out project directory")
    end
    
    unless project.remote
      error("Unable to find git remote for project #{project.name}")
    end
  end
  
  def validate_pigscript!(pigscript_name)
    unless pigscript = project.pigscripts[pigscript_name]
      available_scripts = project.pigscripts.none? ? "No pigscripts found" : "Available scripts:\n#{project.pigscripts.keys.sort.join("\n")}"
      error("Unable to find pigscript #{pigscript_name}\n#{available_scripts}")
    end
    pigscript
  end

  def extract_project_in_dir(project_name=nil)
    # returns [project_name, remote_name]
    # TODO refactor this very messy method
    # when we have a more full sense of which options are supported when
    return unless git.has_dot_git?
    
    remotes = git.remotes(git_organization)
    return if remotes.empty?

    if remote = options[:remote]
      # extract the project whose remote was provided
      [remotes[remote], remote]
    elsif remote = extract_project_from_git_config
      # extract the project setup in git config
      [remotes[remote], remote]
    else
      if project_name
        # search for project by name
        if project_remote = remotes.find {|r_name, p_name| p_name == project_name}
          [project_name, project_remote.first[0]]
        else
          [project_name, nil]
        end
      elsif remotes.values.uniq.size == 1
        # take the only project in the remotes
        [remotes.first[1], remotes.first[0]]
      else
        raise(Mortar::Command::CommandFailed, "Multiple projects in folder and no project specified.\nSpecify which project to use with --project <project name>")
      end
    end
  end

  def extract_project_from_git_config
    remote = git.git("config mortar.remote", false)
    remote == "" ? nil : remote
  end

  def git_organization
    "mortarcode"
  end
  
  def polling_interval
    (options[:polling_interval] || 2.0).to_f
  end

end

module Mortar::Command
  unless const_defined?(:BaseWithApp)
    BaseWithApp = Base
  end
end
