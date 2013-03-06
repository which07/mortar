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
require 'mortar/local/pig'
require 'launchy'


class Mortar::Local::Pig
  attr_reader :command
end


module Mortar::Local
  describe Pig do

    context("install") do

      it "does nothing if told not to" do
        pig = Mortar::Local::Pig.new
        mock(pig).should_do_pig_install?.returns(false)
        FakeFS do
          FileUtils.mkdir_p(File.dirname(pig.local_install_directory))
          FileUtils.rm_rf(pig.local_install_directory, :force => true)
          pig.install
          expect(File.exists?(pig.local_install_directory)).to be_false
        end
      end

      it "handles necessary installation steps" do
        # creates the parent directory, downloads the tgz, extracts it,
        # chmods bin/pig, removes tgz, and notes the installation
        FakeFS do
          pig = Mortar::Local::Pig.new
          local_pig_archive = File.join(pig.local_install_directory, pig.pig_archive_file)
          mock(pig).should_do_pig_install?.returns(true)
          mock(pig).download_file(pig.pig_archive_url, pig.local_install_directory) do
            # Simulate the tgz file being downloaded, this should be deleted
            # before the method finishes executing
            FileUtils.touch(local_pig_archive)
          end
          mock(pig).extract_tgz(local_pig_archive, pig.local_install_directory)
          mock(pig).note_install("pig")
          begin
            previous_stdout, $stdout = $stdout, StringIO.new
            pig.install
          ensure
            $stdout = previous_stdout
          end
          expect(File.exists?(local_pig_archive)).to be_false
        end
      end

    end

    

  end
end
