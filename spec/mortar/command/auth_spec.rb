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
