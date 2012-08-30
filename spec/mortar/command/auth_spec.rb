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
require "mortar/command/auth"

describe Mortar::Command::Auth do
  
  describe "auth:key" do
    it "displays the user's api key" do
      mock(Mortar::Auth).password {"foo_api_key"}
      stderr, stdout = execute("auth:key")
      stderr.should == ""
      stdout.should == <<-STDOUT
foo_api_key
STDOUT
    end
  end
    
  describe "auth:whoami" do
    it "displays the user's email address" do
      mock(Mortar::Auth).user {"sam@mortardata.com"}
      stderr, stdout = execute("auth:whoami")
      stderr.should == ""
      stdout.should == <<-STDOUT
sam@mortardata.com
STDOUT
    end
  end
end
