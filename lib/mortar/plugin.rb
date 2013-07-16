# based on the Rails Plugin

require "stringio"

module Mortar
  class Plugin
    include Mortar::Helpers
    extend Mortar::Helpers

    class ErrorUpdatingSymlinkPlugin < StandardError; end
    class ErrorUpdatingPlugin < StandardError; end
    class ErrorInstallingDependencies < StandardError; end
    class ErrorInstallingPlugin < StandardError; end
    class ErrorPluginNotFound < StandardError; end
    class ErrorLoadingPlugin < StandardError; end

    DEPRECATED_PLUGINS = %w(
      test-plugin
    )

    attr_reader :name, :uri

    def self.directory
      File.expand_path("#{home_directory}/.mortar/plugins")
    end

    def self.list
      Dir["#{directory}/*"].sort.select { |entry|
        File.directory? entry and !(entry =='.' || entry == '..')
      }.map { |folder|
        File.basename(folder)
      }
    end
    
    def self.without_bundler_env 
      original_env = ENV.to_hash
      ENV.delete("BUNDLE_GEMFILE")
      ENV.delete("BUNDLE_PATH")
      ENV.delete("BUNDLE_BIN_PATH")
      ENV.delete("RUBYOPT")
      yield
    ensure
      ENV.replace(original_env.to_hash)
    end

    def self.install_bundle
      # TODO: Deal with the bundler as a runtime dependency issue
      # before moving these require statements to the top.
      begin
        require 'bundler/cli'
        require 'bundler/friendly_errors'
      rescue LoadError => e 
        raise <<-ERROR
Unable to install this plugin. Make sure you have bundler installed:

$ gem install bundler

ERROR
      end

      out = StringIO.new
      $stdout = out
      begin
        bundle_def = Bundler.definition({})
        Bundler.ui = Bundler::UI::Shell.new({})

        # Older versions of Thor and Bundler don't have this option
        if Bundler.ui.respond_to?(:level=)
          Bundler.ui.level = "silent"
        end

        Bundler.settings[:path] = "bundle"
        Bundler::Installer.install(Bundler.root, bundle_def, {
          :standalone => [],
        })
        result = true
      rescue StandardError => e
        out.write e.message
        result = false
      end
      open("#{Plugin.directory}/plugin_install.log", 'a') do |f|
        f.puts out.string
      end
      $stdout = STDOUT
      return result
    end

    def self.load!
      list.each do |plugin|
        next if skip_plugins.include?(plugin)
        load_plugin(plugin)
      end
    end

    def self.load_plugin(plugin)
      begin
        folder = "#{self.directory}/#{plugin}"
        $: << "#{folder}/lib"    if File.directory? "#{folder}/lib"
        load "#{folder}/init.rb" if File.exists?  "#{folder}/init.rb"
      rescue ScriptError, StandardError => error
        styled_error(error, "Unable to load plugin #{plugin}.")
        false
      end
    end

    def self.remove_plugin(plugin)
      FileUtils.rm_rf("#{self.directory}/#{plugin}")
    end

    def self.skip_plugins
      @skip_plugins ||= ENV["SKIP_PLUGINS"].to_s.split(/[ ,]/)
    end

    def initialize(uri)
      @uri = uri
      guess_name(uri)
    end
    
    def git
      @git ||= Mortar::Git::Git.new
    end

    def to_s
      name
    end

    def path
      "#{self.class.directory}/#{name}"
    end

    def install
      if File.directory?(path)
        uninstall
      end
      FileUtils.mkdir_p(self.class.directory)
      Dir.chdir(self.class.directory) do
        git.git("clone #{uri}", check_success=true, check_git_directory=false)
        unless $?.success?
          FileUtils.rm_rf path
          raise Mortar::Plugin::ErrorInstallingPlugin, <<-ERROR
Unable to install plugin #{name}.
Please check the URL and try again.
ERROR
        end
      end
      install_dependencies
      return true
    end

    def install_dependencies
      Dir.chdir(path) do
        Mortar::Plugin.without_bundler_env do
          ENV["BUNDLE_GEMFILE"] = File.expand_path("Gemfile", path)
          if File.exists? ENV["BUNDLE_GEMFILE"]
            unless Mortar::Plugin.install_bundle 
              FileUtils.rm_rf path
              raise Mortar::Plugin::ErrorInstallingDependencies, <<-ERROR
Unable to install dependencies for #{name}.
Error logs stored to #{Plugin.directory}/plugin_install.log
Refer to the documentation for this plugin for help.
ERROR
            end
          end
        end
      end
    end

    def uninstall
      ensure_plugin_exists
      FileUtils.rm_r(path)
    end

    def update
      ensure_plugin_exists
      if File.symlink?(path)
        raise Mortar::Plugin::ErrorUpdatingSymlinkPlugin
      else
        Dir.chdir(path) do
          unless git.git('config --get branch.master.remote').empty?
            message = git.git("pull")
            unless $?.success?
              raise Mortar::Plugin::ErrorUpdatingPlugin, <<-ERROR
Unable to update #{name}.
#{message}
ERROR
            end
          end
        end
        install_dependencies
      end
    end

    private

    def ensure_plugin_exists
      unless File.directory?(path)
        raise Mortar::Plugin::ErrorPluginNotFound, <<-ERROR
#{name} plugin not found.
ERROR
      end
    end

    def guess_name(url)
      @name = File.basename(url)
      @name = File.basename(File.dirname(url)) if @name.empty?
      @name.gsub!(/\.git$/, '') if @name =~ /\.git$/
    end

  end
end
