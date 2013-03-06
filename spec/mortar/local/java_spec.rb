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
require 'mortar/local/java'
require 'launchy'


class Mortar::Local::Java
  attr_reader :command
end


module Mortar::Local
  describe Java do

    context("check_install") do

      it "sets java command if JAVA_HOME is present and exists" do
        java_home = "/foo/bar/jvm"
        ENV['JAVA_HOME'] = java_home
        j = Mortar::Local::Java.new
        FakeFS do
          FileUtils.mkdir_p(java_home + "/bin")
          FileUtils.touch(java_home + "/bin/java")
          j.check_install
          expect(j.command).to eq("/foo/bar/jvm/bin/java")
        end
      end

      it "calls java_home if present and no JAVA_HOME" do
        ENV.delete('JAVA_HOME')
        j = Mortar::Local::Java.new
        exec_path = "/usr/libexec/java_home"
        FakeFS do
          FileUtils.mkdir_p(File.dirname(exec_path))
          FileUtils.touch(exec_path)
          mock(j).run_java_home.returns("/foo/bar/other-jvm")
          j.check_install
          expect(j.command).to eq("/foo/bar/other-jvm/bin/java")
        end
      end

    end


  end
end
