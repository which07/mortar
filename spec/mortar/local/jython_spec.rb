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
require 'mortar/local/jython'



module Mortar::Local
  describe Jython do

    context("update") do

      it "removes existing install and does install" do
        install_dir = "/foo/bar/jython"
        jython = Mortar::Local::Jython.new
        mock(jython).jython_directory.returns(install_dir)
        mock(jython).install
        FakeFS do
          FileUtils.mkdir_p(install_dir)
          expect(File.directory?(install_dir)).to be_true
          jython.update
          expect(File.directory?(install_dir)).to be_false
        end
      end

    end

    context "should_install" do

      it "is true if the directory does not exist" do
        install_dir = "/foo/bar/jython"
        jython = Mortar::Local::Jython.new
        mock(jython).jython_directory.returns(install_dir)
        FakeFS do
          FileUtils.mkdir_p(install_dir)
          expect(jython.should_install).to be_false
        end
      end

      it "is false if the directory already exists" do
        install_dir = "/foo/bar/jython"
        jython = Mortar::Local::Jython.new
        mock(jython).jython_directory.returns(install_dir)
        FakeFS do
          FileUtils.rm_rf(install_dir, :force => true)
          expect(jython.should_install).to be_true
        end
      end

    end

  end
end
