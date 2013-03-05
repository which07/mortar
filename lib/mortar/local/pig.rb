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

require "erb"
require 'ostruct'
require 'tempfile'
require "mortar/local/installutil"

class Mortar::Local::Pig
  include Mortar::Local::InstallUtil

  def command
    return "#{pig_directory}/bin/pig"
  end

  def pig_directory
    return local_install_directory + "/pig"
  end

  def pig_archive_url
    return ENV.fetch('PIG_DISTRO_URL',
                  "https://s3.amazonaws.com/mortar-public-artifacts/pig.tgz")
  end

  def pig_archive_file
    File.basename(pig_archive_url)
  end

  # Determines if a pig install needs to occur, true if no
  # pig install present or a newer version is available
  def should_do_pig_install?
    return (not (File.exists?(pig_directory)))
  end

  # Installs pig for this project if it is not already present
  def install
    if should_do_pig_install?
      FileUtils.mkdir_p(local_install_directory)
       action "Installing pig" do
        download_file(pig_archive_url, local_install_directory)
        extract_tgz(local_install_directory + "/" + pig_archive_file, local_install_directory)

        # This has been seening coming out of the tgz w/o +x so we do
        # here to be sure it has the necessary permissions
        FileUtils.chmod(0755, command)

        File.delete(local_install_directory + "/" + pig_archive_file)
        note_install("pig")
      end
    end
  end

  # run the pig script with user supplied pig parameters
  def run_script(pig_script, pig_parameters)
    run_pig_command(" -f #{pig_script.path}", pig_parameters)
  end

  def illustrate_alias(pig_script, pig_alias, skip_pruning, pig_parameters)
    cmd = "-e 'illustrate "

    # Parameters have to be entered before the script or the script will
    # be parsed w/o the parameter values being set, resulting in an
    # 'Undefined parameter' error.
    mortar_pig_params = automatic_pig_parameters
    mortar_pig_params.concat(pig_parameters).each{ |param|
        cmd += "-param #{param['name']}=#{param['value']} "
      }

    cmd += "-script #{pig_script.path} -out illustrate.out #{pig_alias} "
    if skip_pruning
      cmd += " -skipPruning "
    end
    cmd += "'"
    run_pig_command(cmd, [])
  end

  # Run pig with the specified command ('command' is anything that
  # can be appended to the command line invocation of Pig that will
  # get it to do something interesting, such as '-f some-file.pig'
  def run_pig_command(cmd, parameters = nil)
    # Generate the script for running the command, then
    # write it to a temp script which will be exectued
    script_text = script_for_command(cmd, parameters)
    script = Tempfile.new("mortar-")
    script.write(script_text)
    script.close(false)
    FileUtils.chmod(0755, script.path)
    system(script.path)
    script.unlink
  end

  # Generates a bash script which sets up the necessary environment and
  # then runs the pig command
  def script_for_command(cmd, parameters)
    template_params = pig_command_script_template_parameters(cmd, parameters)
    erb = ERB.new(File.read(pig_command_script_template_path), 0, "%<>")
    return erb.result(BindingClazz.new(template_params).get_binding)
  end

  # Path to the template which generates the bash script for running pig
  def pig_command_script_template_path
    return File.expand_path("../../templates/script/runpig.sh", __FILE__)
  end

  # Parameters necessary for rendering the bash script template
  def pig_command_script_template_parameters(cmd, pig_parameters)
    template_params = {}
    mortar_pig_params = automatic_pig_parameters
    template_params['pig_params'] = mortar_pig_params.concat(pig_parameters)
    template_params['pig_home'] = pig_directory
    template_params['pig_classpath'] = "#{pig_directory}/piglib/*"
    template_params['classpath'] = "#{pig_directory}/lib/*"
    template_params['project_home'] = File.expand_path("..", local_install_directory)
    template_params['local_install_dir'] = local_install_directory
    template_params['pig_sub_command'] = cmd
    template_params['pig_opts'] = pig_options
    return template_params
  end

  # Returns a hash of settings that need to be passed
  # in via pig options
  def pig_options
    opts = {}
    opts['fs.s3n.awsAccessKeyId'] = ENV['AWS_ACCESS_KEY']
    opts['fs.s3n.awsSecretAccessKey'] = ENV['AWS_SECRET_KEY']
    opts['pig.events.logformat'] = 'humanreadable'
    return opts
  end

  # Pig Paramenters that are supplied directly from Mortar when
  # running on the server side.  We duplicate these here.
  def automatic_pig_parameters
    params = {}
    if ENV['MORTAR_EMAIL_S3_ESCAPED']
      params['MORTAR_EMAIL_S3_ESCAPED'] = ENV['MORTAR_EMAIL_S3_ESCAPED']
    else
      params['MORTAR_EMAIL_S3_ESCAPED'] = Mortar::Auth.user_s3_safe
    end
    # Coerce into the same format as pig parameters that were
    # passed in via the command line or a parameter file
    param_list = []
    params.each{ |k,v|
      param_list.push({"name" => k, "value" => v})
    }
    return param_list
  end

  # Allows us to use a hash for template variables
  class BindingClazz
    def initialize(attrs)
      attrs.each{ |k, v|
        # set an intstance variable with the key name so the binding will find it in scope
        self.instance_variable_set("@#{k}".to_sym, v)
      }
    end
    def get_binding()
      binding
    end
  end

end
