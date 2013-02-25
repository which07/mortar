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
# Portions of this code from heroku (https://github.com/heroku/heroku/) Copyright Heroku 2008 - 2012,
# used under an MIT license (https://github.com/heroku/heroku/blob/master/LICENSE).
#

require "tempfile"
require "mortar"
require "mortar/helpers"
require "mortar/errors"

class Mortar::Local
  class << self
    include Mortar::Helpers

    def illustrate(pig_script, pig_alias, output_directory = ".")
      cmd = "-e 'illustrate "
      mortar_params.each{ |name, value|
        cmd += "-param #{name}=#{value} "
      }
      cmd += "-script #{pig_script.path} "
      cmd += "-out #{output_directory}/pig.out #{pig_alias}'"
      run_pig_process(cmd)
    end

    def run(pig_script, local = true)
      run_pig_process(" -f #{pig_script.path}", local)
    end


    def run_pig_process(pig_command, local)
log4jproperties = "
log4j.rootLogger=fatal, PIGCONSOLE
log4j.appender.PIGCONSOLE=org.apache.log4j.ConsoleAppender
log4j.appender.PIGCONSOLE.target=System.err
log4j.appender.PIGCONSOLE.layout=org.apache.log4j.PatternLayout
log4j.appender.PIGCONSOLE.layout.ConversionPattern=%m%n
log4j.appender.PIGCONSOLE.encoding=UTF-8
log4j.logger.org.apache.hadoop=fatal, PIGCONSOLE
log4j.logger.com.mortardata.hawk.progress.HawkProgressEventHandler=info, PIGCONSOLE
"
      # Write out the log4j properties file
      l4jpath = ".mortar-mud/log4j.properties"
      if not File.exists?(l4jpath) then
        File.open(l4jpath, 'w') {|f| f.write(log4jproperties) }
      end



      cmd = "#!/bin/sh\n\n"

      # Throw in the environment variables
      pig_env(local).each{ |name, value|
        cmd += "export #{name}=#{value}\n"
      }
      # Now, put us in the right directory (paths in mortar
      # projects are relative to the pigscripts directory)
      cmd += "cd " + realpath("pigscripts") + "\n"

      cmd += ". " + realpath(".mortar-mud/pythonenv/bin/activate") + "\n"

      if local then
        cmd += pig_exec_path + " -exectype local \\\n"
      else
        cmd += pig_exec_path + " -exectype mapreduce \\\n"
      end

      cmd += "-log4jconf " + realpath(".mortar-mud/log4j.properties") + " \\\n"

      mortar_params.each{ |name, value|
        cmd += "-param #{name}=#{value} \\\n"
      }
      cmd += "-propertyFile " + realpath(".mortar-mud/pig.properties") + " \\\n"
      cmd += pig_command
      if not local then
        # On the server side run pig in the background and write
        # out the pid so the controller and communicate with pig
        cmd += " & \n\n"
        cmd += "echo $! > pig.pid\n\n"
      end
      cmd += "\n\n"

      script = Tempfile.new("mortar-mud-")
      script.write(cmd)
      script.close(false)
      FileUtils.chmod(0755, script.path)

      # DEBUG DEBUG DEBUG
      `cp #{script.path} #{script.path}.bak`
      print "Running #{script.path}.bak\n"

      # Let's run this sucker!
      system(script.path)

      # Now be polite and clean after yourself
      script.unlink

    end


    def check_java
      # Todo: walk around and look for a java install based upon the
      # os and release number.  Also, verify that JAVA_HOME actually
      # exists.
      if ENV['JAVA_HOME']
        return true
      elsif File.exists?("/usr/libexec/java_home")
        # OSX has a nice little tool for finding this value
        ENV['JAVA_HOME'] = `/usr/libexec/java_home`
        return true
      else
        return false
      end
    end

    def check_python
      if os_platform_name().start_with?('darwin')
        check_python_osx()
      else
        check_python_nix()
      end
    end

    def check_python_virtenv()
      FileUtils.mkdir_p(".mortar-mud")
      if File.exists?(".mortar-mud/pythonenv")
        return true
      else
        `#{python_exec_path(false)} -m virtualenv --help`
        if (0 != $?.to_i)
          return false
        else
          `#{python_exec_path(false)} -m virtualenv .mortar-mud/pythonenv`
          return (0 == $?.to_i)
        end
      end
    end

    # Installs pip and any dependencies
    def check_python_env
      if !check_install_pip()
        return false
      end
      if !File.exists?("requirements.txt")
        return true
      end
      `. .mortar-mud/pythonenv/bin/activate
       .mortar-mud/pythonenv/bin/pip install --requirement requirements.txt`
      return (0 == $?.to_i)
    end

    def check_install_pip
      if File.exists?(".mortar-mud/pythonenv/bin/pip")
        return true
      end
      FileUtils.mkdir_p(".mortar-mud/pythonenv/bin")
      url = "https://raw.github.com/pypa/pip/master/contrib/get-pip.py"
      `cd .mortar-mud;
       if [ -z "$(which wget)" ]; then
           curl -O #{url}
       else
           wget #{url}
       fi`
      if (0 != $?.to_i)
        return false
      end
      `cd .mortar-mud;
       . pythonenv/bin/activate
       #{python_exec_path} get-pip.py`
      result = $?
      File.delete(".mortar-mud/get-pip.py")
      return (0 == result.to_i)
    end

    def check_python_osx
      return download_and_extract("https://s3.amazonaws.com/mortar-public-artifacts/mortar-python-osx.tgz", 'python')
    end

    def check_python_nix
      # Todo: be much more robost.  Possibly check for the appropriate version.
      path_to_python = `which python`
      if path_to_python
        return true
      else
        return false
      end
    end

    def check_aws_access
      FileUtils.mkdir_p(".mortar-mud")
      if File.exists?(".mortar-mud/pig.properties")
        return true
      else
        if (!(ENV['AWS_ACCESS_KEY'] and ENV['AWS_SECRET_KEY'])) then
          return false
        else
          File.open(".mortar-mud/pig.properties", 'w') { |f|
            f.write("fs.s3n.awsAccessKeyId=#{ENV['AWS_ACCESS_KEY']}\n")
            f.write("fs.s3n.awsSecretAccessKey=#{ENV['AWS_SECRET_KEY']}\n")
          }
        end
      end
    end

    def install_pig
      FileUtils.mkdir_p(".mortar-mud")
      download_and_extract("https://s3.amazonaws.com/mortar-public-artifacts/mortar-mud.tgz", "pig")
    end

    def pig_env(local_run = true)
      pigenv = {
        'PIG_HOME' => realpath(".mortar-mud/pig"),
        'PIG_CLASSPATH' => realpath(".mortar-mud/pig/piglib") + "/*",
        'CLASSPATH' => realpath(".mortar-mud/log4j.properties") + ":" + realpath(".mortar-mud/pig/lib"),
        'PIG_MAIN_CLASS' => "com.mortardata.hawk.HawkMain",
      }

      if local_run then
        pigenv['PIG_OPTS'] = '-Dpig.events.logformat=humanreadable'
      end
      if has_mortar_python
        pigenv['PATH'] = realpath(".mortar-mud/python/bin") + ":" + ENV['PATH']
      end

      return pigenv
    end

    # Path to the mortar installed pig executable
    def pig_exec_path
      return realpath(".mortar-mud/pig/bin/pig")
    end

    def python_exec_path(inenv=true)
      if inenv
        return realpath(".mortar-mud/pythonenv/bin/python")
      else
        if has_mortar_python
          return realpath(".mortar-mud/python/bin/python")
        else
          return 'python'
        end
      end
    end

    def mortar_params
      # todo: add the remaining automatic parameters that are missing
      params = {}
      if ENV['MORTAR_EMAIL_S3_ESCAPED']
        params['MORTAR_EMAIL_S3_ESCAPED'] = ENV['MORTAR_EMAIL_S3_ESCAPED']
      else
        params['MORTAR_EMAIL_S3_ESCAPED'] = Mortar::Auth.user_s3_safe
      end
      return params
    end

    def realpath(relpath)
      if defined? File.realpath
        return File.realpath(relpath)
      else
        p = Pathname.new(relpath).realpath
        return p.to_s
      end
    end

    def download_and_extract(url, subdirectory)
      FileUtils.mkdir_p(".mortar-mud")
      if File.exists?(".mortar-mud/#{subdirectory}")
        return true
      else
        # todo: there's almost certainly a ruby call we can make to grab this and/or untar it, the urls
        # should be configurable so we can override for development, and we should have error handling
        # in case the shell out fails
        `cd .mortar-mud;
         if [ -z "$(which wget)" ]; then
             curl -s #{url} | tar xz
         else
             wget -qO- #{url} | tar xz
         fi`
        return ($?.to_i == 0)
      end
    end

    def os_platform_name
      if defined? RbConfig
        return RbConfig::CONFIG['target_os']
      else
        return Config::CONFIG['target_os']
      end
    end

    def has_mortar_python
      return File.directory?(".mortar-mud/python")
    end


    def check_install()
      unless Mortar::Local.check_java()
        error("You do not appear to have a usable java install.  Please install java and/or set JAVA_HOME")
      end

      unless Mortar::Local.check_python()
        error("You do not appear to have a usable python install.")
      end

      unless Mortar::Local.check_python_virtenv()
        error("Please install python-virtualenv")
      end

      unless Mortar::Local.check_python_env()
        error("Failed installing dependencies")
      end

      unless Mortar::Local.check_aws_access()
        msg =  "Please specify your aws access key via enviroment variable AWS_ACCESS_KEY\n"
        msg += "and your aws secret key via enviroment variable AWS_SECRET_KEY"
        error(msg)
      end

      # This function is idempotent and so a no-op if
      # pig is already setup locally
      Mortar::Local.install_pig()
    end

  end
end
