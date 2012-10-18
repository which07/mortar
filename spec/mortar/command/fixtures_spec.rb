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
require 'mortar/command/fixtures'
require 'mortar/api/fixtures'

module Mortar::Command
  describe Fixtures do
    before(:each) do
      stub_core
      @git = Mortar::Git::Git.new
    end

    context("index") do

      it "errors when missing command" do
        with_git_initialized_project do |p|
          stderr, stdout = execute("fixtures:head s3n://tbmmsd/*.tsv.* 5", p, @git)
          stderr.should == <<-STDERR
 !    Usage: mortar fixtures:head INPUT_URL NUM_ROWS FIXTURE_NAME
 !    Must specifiy INPUT_URL, NUM_ROWS, and FIXTURE_NAME.
STDERR
        end
      end

      it "requests and reports on a successful fixtures:head" do
        with_git_initialized_project do |p|
          fixture_id = "12345abcde"
          name = "My_pet_fixture"
          url = "s3://my_pet_fixture"
          num_rows = "60"

          sample_s3_urls = [ {'url' => "url1",
                              'name' => "url1_name"}]

          mock(Mortar::Auth.api).post_fixture_limit(p.name, name, url, num_rows) {Excon::Response.new(:body => {"fixture_id" => fixture_id})}
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_PENDING, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_CREATING, "status_description" => "Creating"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_SAVING, "status_description" => "Uploading"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_CREATED, "status_description" => "Success", "name" => name, "sample_s3_urls" => sample_s3_urls})).ordered

          any_instance_of(Mortar::Command::Fixtures) do |base|
            mock(base).download_to_file(sample_s3_urls[0]['url'], "fixtures/#{name}/#{sample_s3_urls[0]['name']}")
          end

          stderr, stdout = execute("fixtures:head #{url} #{num_rows} #{name} --polling_interval 0.05", p, @git)

          stdout.should == <<-STDOUT
WARNING: Creating fixtures with more than 50 rows is not recommended.  Large local fixtures may cause slowness when using Mortar.

Requesting fixture creation... done

\r\e[0KStatus: Pending... /\r\e[0KStatus: Creating... -\r\e[0KStatus: Uploading... \\\r\e[0KStatus: Success \n\n
STDOUT

        end
      end

      it "requests and reports on a failed fixtures:head" do
        with_git_initialized_project do |p|
          fixture_id = "12345abcde"
          name = "My_pet_fixture"
          url = "s3://my_pet_fixture"
          num_rows = "60"

          sample_s3_urls = [ {'url' => "url1",
                              'name' => "url1_name"}]

          mock(Mortar::Auth.api).post_fixture_limit(p.name, name, url, num_rows) {Excon::Response.new(:body => {"fixture_id" => fixture_id})}
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_PENDING, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_CREATING, "status_description" => "Creating"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_SAVING, "status_description" => "Uploading"})).ordered
          mock(Mortar::Auth.api).get_fixture(fixture_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Fixtures::STATUS_FAILED, 
            "status_description" => "Failed", 
            "name" => name,
            "error_message" => "This is an error message.",
            "error_type" => "UserError" })).ordered

          stderr, stdout = execute("fixtures:head #{url} #{num_rows} #{name} --polling_interval 0.05", p, @git)

          stdout.should == <<-STDOUT
WARNING: Creating fixtures with more than 50 rows is not recommended.  Large local fixtures may cause slowness when using Mortar.

Requesting fixture creation... done

\r\e[0KStatus: Pending... /\r\e[0KStatus: Creating... -\r\e[0KStatus: Uploading... \\\r\e[0KStatus: Failed \n
STDOUT

stderr.should == <<-STDERR
 !    Fixture generation failed with UserError:
 !    
 !    This is an error message.
STDERR

        end
      end


      it "tries to create a fixture in an existing directory" do
        with_git_initialized_project do |p|
          fixture_id = "12345abcde"
          name = "My_pet_fixture"
          url = "s3://my_pet_fixture"
          num_rows = "60"

          fixtures_dir = File.join(Dir.pwd, "fixtures", name)
          FileUtils.mkdir_p(fixtures_dir)

          stderr, stdout = execute("fixtures:head #{url} #{num_rows} #{name} --polling_interval 0.05", p, @git)

          stderr.should == <<-STDERR
 !    Fixture #{name} already exists.
STDERR
        end
      end


    
    end
  end
end