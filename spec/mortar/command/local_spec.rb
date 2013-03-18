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

require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/command/local'
require 'launchy'

module Mortar::Command
  describe Local do

    context("illustrate") do
      it "errors when an alias is not provided" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("local:illustrate my_script", p)
          stderr.should == <<-STDERR
 !    Usage: mortar local:illustrate PIGSCRIPT ALIAS
 !    Must specify PIGSCRIPT and ALIAS.
STDERR
        end
      end

      it "errors when the script doesn't exist" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_other_script.pig"))
          stderr, stdout = execute("local:illustrate my_script some_alias", p)
          stderr.should == <<-STDERR
 !    Unable to find pigscript my_script
 !    Available scripts:
 !    my_other_script
STDERR
        end
      end

      it "calls the illustrate command when envoked correctly" do
        with_git_initialized_project do |p|
          script_name = "some_script"
          script_path = File.join(p.pigscripts_path, "#{script_name}.pig")
          write_file(script_path)
          pigscript = Mortar::Project::PigScript.new(script_name, script_path)
          mock(Mortar::Project::PigScript).new(script_name, script_path).returns(pigscript)
          any_instance_of(Mortar::Local::Controller) do |u|
            mock(u).illustrate(pigscript, "some_alias", [], false).returns(nil)
          end
          stderr, stdout = execute("local:illustrate #{script_name} some_alias", p)
          stderr.should == ""
        end
      end

    # illustrate
    end

    context("run") do

      it "errors when the script doesn't exist" do
        with_git_initialized_project do |p|
          write_file(File.join(p.pigscripts_path, "my_other_script.pig"))
          write_file(File.join(p.controlscripts_path, "my_control_script.py"))
          stderr, stdout = execute("local:run my_script", p)
          stderr.should == <<-STDERR
 !    Unable to find a pigscript or controlscript for my_script
 !    
 !    Available pigscripts:
 !    my_other_script
 !    
 !    Available controlscripts:
 !    my_control_script
STDERR
        end
      end

      it "calls the run command when envoked correctly" do
        with_git_initialized_project do |p|
          script_name = "some_script"
          script_path = File.join(p.pigscripts_path, "#{script_name}.pig")
          write_file(script_path)
          pigscript = Mortar::Project::PigScript.new(script_name, script_path)
          mock(Mortar::Project::PigScript).new(script_name, script_path).returns(pigscript)
          any_instance_of(Mortar::Local::Controller) do |u|
            mock(u).run(pigscript, []).returns(nil)
          end
          stderr, stdout = execute("local:run #{script_name}", p)
          stderr.should == ""
        end
      end
    # run
    end

    context("configure") do

      it "errors if java can't be found" do
        any_instance_of(Mortar::Local::Java) do |j|
          stub(j).check_install.returns(false)
        end
        stderr, stdout = execute("local:configure")
        stderr.should == Mortar::Local::Controller::NO_JAVA_ERROR_MESSAGE.gsub(/^/, " !    ")
      end

      it "errors if python can't be found" do
        any_instance_of(Mortar::Local::Java) do |j|
          stub(j).check_install.returns(true)
        end
        any_instance_of(Mortar::Local::Pig) do |j|
          stub(j).install.returns(true)
        end
        any_instance_of(Mortar::Local::Python) do |j|
          stub(j).check_or_install.returns(false)
        end
        stderr, stdout = execute("local:configure")
        stderr.should == Mortar::Local::Controller::NO_PYTHON_ERROR_MESSAGE.gsub(/^/, " !    ")
      end

      it "checks for java, installs pig/python, and configures a virtualenv" do
        any_instance_of(Mortar::Local::Java) do |j|
          mock(j).check_install.returns(true)
        end
        any_instance_of(Mortar::Local::Pig) do |j|
          mock(j).install.returns(true)
        end
        any_instance_of(Mortar::Local::Python) do |j|
          mock(j).check_or_install.returns(true)
        end
        any_instance_of(Mortar::Local::Python) do |j|
          mock(j).setup_project_python_environment.returns(true)
        end
        any_instance_of(Mortar::Local::Jython) do |j|
          mock(j).install_or_update.returns(true)
        end
        stderr, stdout = execute("local:configure")
        stderr.should == ""
      end

    # configure
    end

  end
end

