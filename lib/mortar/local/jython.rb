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

require "mortar/local/installutil"

class Mortar::Local::Jython
  include Mortar::Local::InstallUtil

  JYTHON_VERSION = '2.5.2'
  JYTHON_JAR_NAME = 'jython_installer-' + JYTHON_VERSION + '.jar'
  JYTHON_JAR_DIR = "http://s3.amazonaws.com/hawk-dev-software-mirror/jython/jython-2.5.2/"

  def install_or_update
    if should_install
      action("Installing jython") do
        install
      end
    elsif should_update
      action("Updating jython") do
        update
      end
    end
  end

  def should_install
    not File.exists?(jython_directory)
  end

  def install
    unless File.exists?(local_install_directory + '/' + JYTHON_JAR_NAME)
        download_file(JYTHON_JAR_DIR + JYTHON_JAR_NAME, local_install_directory)
    end

    `$JAVA_HOME/bin/java -jar #{local_install_directory + '/' + JYTHON_JAR_NAME} -s -d #{jython_directory}`
    FileUtils.mkdir_p jython_cache_directory
    FileUtils.chmod_R 0777, jython_cache_directory

    FileUtils.rm(local_install_directory + '/' + JYTHON_JAR_NAME)
    note_install('jython')
  end

  def should_update
    return is_newer_version('jython', JYTHON_JAR_DIR + JYTHON_JAR_NAME)
  end

  def update
    FileUtils.rm_r(jython_directory)
    install
  end

  # ##################################################################
  # Almost all of below is copied/pasted/tweaked from pig.rb so please
  # don't actually use it beyond the prototype it was indended for.
  # ##################################################################

  def run(cmd_args)
    # Generate the script for running the command, then
    # write it to a temp script which will be exectued
    script_text = render_script_text(cmd_args)
    # puts script_text
    script = Tempfile.new("mortar-jython")
    script.write(script_text)
    script.close(false)
    FileUtils.chmod(0755, script.path)
    system(script.path)
    script.unlink
    return (0 == $?.to_i)
  end

  def render_script_text(cmd_args)
    params = jython_template_params(cmd_args)
    erb = ERB.new(File.read(jython_command_script_template_path), 0, "%<>")
    erb.result(BindingClazz.new(params).get_binding)
  end

  def jython_template_params(cmd_args)
    pig = Mortar::Local::Pig.new
    pig_directory = pig.pig_directory
    template_params = {}
    template_params['pig_home'] = pig_directory
    template_params['pig_classpath'] = "#{pig_directory}/lib-pig/*:#{jython_directory}/jython.jar"
    template_params['classpath'] = "#{pig_directory}/lib/*:#{jython_directory}/jython.jar:#{pig_directory}/conf/jets3t.properties"
    template_params['local_install_dir'] = local_install_directory
    template_params['jython_cmd_parts'] = cmd_args
    template_params['java_props'] = java_properties
    return template_params
  end

  def java_properties
    opts = {}
    opts['python.verbose'] = 'error'
    opts['jython.output'] = true
    opts['python.home'] = jython_directory
    opts['python.path'] = local_install_directory + "/../controlscripts"
    opts['python.cachedir'] = jython_cache_directory
    return opts
  end

  # Path to the template which generates the bash script for running pig
  def jython_command_script_template_path
    File.expand_path("../../templates/script/runjython.sh", __FILE__)
  end

  # Allows us to use a hash for template variables
  class BindingClazz
    def initialize(attrs)
      attrs.each{ |k, v|
        # set an instance variable with the key name so the binding will find it in scope
        self.instance_variable_set("@#{k}".to_sym, v)
      }
    end
    def get_binding()
      binding
    end
  end

end
