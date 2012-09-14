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
require 'mortar/command/datasets'
require 'mortar/api/datasets'

module Mortar::Command
  describe Datasets do
    before(:each) do
      stub_core
    end

    context("index") do

      it "errors when missing command" do
        with_git_initialized_project do |p|
          stderr, stdout = execute("datasets:sample s3n://tbmmsd/*.tsv.* 0.001", p)
          stderr.should == <<-STDERR
 !    Usage: mortar datasets:sample INPUT_URL PERCENT_TO_RETURN DATASET_NAME
 !    Must specifiy INPUT_URL, PERCENT_TO_RETURN, and DATASET_NAME.
STDERR
        end
      end

      it "requests and reports on a successful datasets:sample" do
        with_git_initialized_project do |p|
          dataset_id = "12345abcde"
          name = "My_pet_dataset"
          url = "s3://my_pet_dataset"
          pct = "0.1"

          sample_s3_urls = [ {'url' => "url1",
                              'name' => "url1_name"}]

          mock(Mortar::Auth.api).post_dataset_sample(p.name, name, url, pct) {Excon::Response.new(:body => {"dataset_id" => dataset_id})}
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_PENDING, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_CREATING, "status_description" => "Creating"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_SAVING, "status_description" => "Uploading"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_CREATED, "status_description" => "Success", "name" => name, "sample_s3_urls" => sample_s3_urls})).ordered

          any_instance_of(Mortar::Command::Datasets) do |base|
            mock(base).download_to_file(sample_s3_urls[0]['url'], "datasets/#{name}/#{sample_s3_urls[0]['name']}")
          end

          stderr, stdout = execute("datasets:sample #{url} #{pct} #{name} --polling_interval 0.05")

        end
      end

      it "requests and reports on a successful datasets:limit" do
        with_git_initialized_project do |p|
          dataset_id = "12345abcde"
          name = "My_pet_dataset"
          url = "s3://my_pet_dataset"
          num_rows = "20"

          sample_s3_urls = [ {'url' => "url1",
                              'name' => "url1_name"}]

          mock(Mortar::Auth.api).post_dataset_sample(p.name, name, url, num_rows) {Excon::Response.new(:body => {"dataset_id" => dataset_id})}
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_PENDING, "status_description" => "Pending"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_CREATING, "status_description" => "Creating"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_SAVING, "status_description" => "Uploading"})).ordered
          mock(Mortar::Auth.api).get_dataset(dataset_id).returns(Excon::Response.new(:body => {"status_code" => Mortar::API::Datasets::STATUS_CREATED, "status_description" => "Success", "name" => name, "sample_s3_urls" => sample_s3_urls})).ordered

          any_instance_of(Mortar::Command::Datasets) do |base|
            mock(base).download_to_file(sample_s3_urls[0]['url'], "datasets/#{name}/#{sample_s3_urls[0]['name']}")
          end

          stderr, stdout = execute("datasets:sample #{url} #{num_rows} #{name} --polling_interval 0.05")

        end
      end
    
    end
  end
end