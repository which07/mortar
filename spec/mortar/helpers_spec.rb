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

require "spec_helper"
require "mortar/helpers"
require 'fakefs/spec_helpers'

module Mortar
  describe Helpers do
    include Mortar::Helpers

    context "display_object" do

      it "should display Array correctly" do
        capture_stdout do
          display_object([1,2,3])
        end.should == <<-OUT
1
2
3
OUT
      end

      it "should display { :header => [] } list correctly" do
        capture_stdout do
          display_object({:first_header => [1,2,3], :last_header => [7,8,9]})
        end.should == <<-OUT
=== first_header
1
2
3

=== last_header
7
8
9

OUT
      end

      it "should display String properly" do
        capture_stdout do
          display_object('string')
        end.should == <<-OUT
string
OUT
      end

    end
    
    context "write_to_file" do
      it "should write data to a directory that does not yet exist" do
        
        # use FakeFS file system
        include FakeFS::SpecHelpers
        
        filepath = File.join(Dir.tmpdir, "my_new_dir", "my_new_file.txt")
        data = "foo\nbar"
        write_to_file(data, filepath)
        File.exists?(filepath).should be_true
        infile = File.open(filepath, "r")
        infile.read.should == data
        infile.close()
      end
    end

    context "ensure_dir_exists" do
      it "does not have an existing directory" do
        FakeFS do
          dir_name = "./foo-bar-dir"
          expect(File.directory?(dir_name)).to be_false
          ensure_dir_exists(dir_name)
          expect(File.directory?(dir_name)).to be_true
        end
      end

      it "does have an existing directory" do
        FakeFS do
          dir_name = "./foo-bar-dir"
          FileUtils.mkdir_p(dir_name)
          expect(File.directory?(dir_name)).to be_true
          ensure_dir_exists(dir_name)
          expect(File.directory?(dir_name)).to be_true
        end
      end

    end

  end
end
