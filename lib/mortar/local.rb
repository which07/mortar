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

    def run(pig_script)

      cmd = "#!/bin/sh\n\n"

      # Throw in the environment variables
      pig_env.each{ |name, value|
        cmd += "export #{name}=#{value}\n"
      }
      # Now, put us in the right directory (paths in mortar
      # projects are relative to the pigscripts directory)
      cmd += "cd " + realpath("pigscripts") + "\n"


      cmd += pig_exec_path + " -exectype local \\\n"
      mortar_params.each{ |name, value|
        cmd += "-param #{name}=#{value} \\\n"
      }
      cmd += "-propertyFile " + realpath(".mortar-mud/pig.properties") + " \\\n"
      cmd += "-file " + pig_script.path
      cmd += "\n\n"

      script = Tempfile.new("mortar-mud-")
      script.write(cmd)
      script.close(false)
      FileUtils.chmod(0755, script.path)

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

    def pig_env
      # todo: separate out classpath and pig_classpath to two diff diretories
      # once the mud installer does so.  Also, do these need to be absolute
      # paths?
      pigenv = {
        'PIG_HOME' => realpath(".mortar-mud/pig"),
        'PIG_CLASSPATH' => realpath(".mortar-mud/pig/piglib") + "/*",
        'CLASSPATH' => realpath(".mortar-mud/pig/lib")  + "/*"
      }
      if has_mortar_python
        pigenv['PATH'] = realpath(".mortar-mud/python/bin") + ":" + ENV['PATH']
      end

      return pigenv
    end

    # Path to the mortar installed pig executable
    def pig_exec_path
      return realpath(".mortar-mud/pig/bin/pig")
    end

    def mortar_params
      # todo: add the remaining automatic parameters that are missing
      params = {
        'MORTAR_EMAIL_S3_ESCAPED' => Mortar::Auth.user_s3_safe
      }
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

  end
end
