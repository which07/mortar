require "mortar"
require "mortar/helpers"

# workaround for rescue/reraise to define errors in command.rb failing in 1.8.6
#if RUBY_VERSION =~ /^1.8.6/
#  require('mortar-api')
#  require('rest_client')
#end

class Mortar::CLI

  extend Mortar::Helpers

  def self.start(*args)
    begin
      if $stdin.isatty
        $stdin.sync = true
      end
      if $stdout.isatty
        $stdout.sync = true
      end
      command = args.shift.strip rescue "help"
      display("Hello, world!")
      #Mortar::Command.load
      #Mortar::Command.run(command, args)
    rescue Interrupt
      `stty icanon echo`
      error("Command cancelled.")
    rescue => error
      styled_error(error)
      exit(1)
    end
  end

end
