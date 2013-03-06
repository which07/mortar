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
require 'mortar/local/installutil'
require 'launchy'

module Mortar::Local
  describe InstallUtil do
    include FakeFS::SpecHelpers

    class InstallUtilClass
    end

    before(:each) do
      @installutil = InstallUtilClass.new
      @installutil.extend(Mortar::Local::InstallUtil)
    end

    context("install_date") do

      it "nil if never installed" do
        expect(@installutil.install_date('foo')).to be_nil
      end

      it "contents of file if present, converted to int" do
        install_file_path = @installutil.install_file_for("foo")
        install_date = 123456
        FakeFS do
          FileUtils.mkdir_p(File.dirname(install_file_path))
          File.open(install_file_path, "w") do |file|
            file.puts(install_date.to_s)
          end
          expect(@installutil.install_date('foo')).to eq(install_date)
        end
      end

    end

    context("note-install") do

      it "creates a file in the directory with the current time" do
        install_file_path = @installutil.install_file_for("foo")
        current_date = 123456
        stub(Time).now.returns(current_date)
        FakeFS do
          FileUtils.mkdir_p(File.dirname(install_file_path))
          @installutil.note_install("foo")
          expect(File.exists?(install_file_path)).to be_true
        end
      end

    end

  end
end
