require "spec_helper"
require "mortar/command"
require 'json' #FOR WEBMOCK

class FakeResponse

  attr_accessor :body, :headers

  def initialize(attributes)
    self.body, self.headers = attributes[:body], attributes[:headers]
  end

  def to_s
    body
  end

end

describe Mortar::Command do
  before {
    Mortar::Command.load
    stub_core # setup fake auth
  }

  describe "parsing errors" do
    it "extracts error messages from response when available in XML" do
      Mortar::Command.extract_error('<errors><error>Invalid app name</error></errors>').should == 'Invalid app name'
    end

    it "extracts error messages from response when available in JSON" do
      Mortar::Command.extract_error("{\"error\":\"Invalid app name\"}").should == 'Invalid app name'
    end

    it "extracts error messages from response when available in plain text" do
      response = FakeResponse.new(:body => "Invalid app name", :headers => { :content_type => "text/plain; charset=UTF8" })
      Mortar::Command.extract_error(response).should == 'Invalid app name'
    end

    it "shows Internal Server Error when the response doesn't contain a XML or JSON" do
      Mortar::Command.extract_error('<h1>HTTP 500</h1>').should == "Internal server error."
    end

    it "shows Internal Server Error when the response is not plain text" do
      response = FakeResponse.new(:body => "Foobar", :headers => { :content_type => "application/xml" })
      Mortar::Command.extract_error(response).should == "Internal server error."
    end

    it "allows a block to redefine the default error" do
      Mortar::Command.extract_error("Foobar") { "Ok!" }.should == 'Ok!'
    end

    it "doesn't format the response if set to raw" do
      Mortar::Command.extract_error("Foobar", :raw => true) { "Ok!" }.should == 'Ok!'
    end

    it "handles a nil body in parse_error_xml" do
      lambda { Mortar::Command.parse_error_xml(nil) }.should_not raise_error
    end

    it "handles a nil body in parse_error_json" do
      lambda { Mortar::Command.parse_error_json(nil) }.should_not raise_error
    end
  end

  it "correctly resolves commands" do
    class Mortar::Command::Test; end
    class Mortar::Command::Test::Multiple; end

    require "mortar/command/help"

    Mortar::Command.parse("unknown").should be_nil
    Mortar::Command.parse("help").should include(:klass => Mortar::Command::Help, :method => :index)
  end
  
  context "when no commands match" do

    it "displays the version if -v or --version is used" do
      mortar("-v").should == <<-STDOUT
#{Mortar::USER_AGENT}
STDOUT
      mortar("--version").should == <<-STDOUT
#{Mortar::USER_AGENT}
STDOUT
    end

    it "does not suggest similar commands if there are none" do
      original_stderr, original_stdout = $stderr, $stdout
      $stderr = captured_stderr = StringIO.new
      $stdout = captured_stdout = StringIO.new
      begin
        execute("sandwich")
      rescue SystemExit
      end
      captured_stderr.string.should == <<-STDERR
 !    `sandwich` is not a mortar command.
 !    See `mortar help` for a list of available commands.
STDERR
      captured_stdout.string.should == ""
      $stderr, $stdout = original_stderr, original_stdout
    end
  end
end
