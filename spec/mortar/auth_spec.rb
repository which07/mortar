require "spec_helper"
require "mortar/auth"
require "mortar/helpers"

module Mortar
  describe Auth do
    include Mortar::Helpers

    before do
      ENV['MORTAR_API_KEY'] = nil

      @cli = Mortar::Auth
      @cli.stub!(:check)
      @cli.stub!(:display)
      @cli.stub!(:running_on_a_mac?).and_return(false)
      @cli.credentials = nil

      FakeFS.activate!

      FakeFS::File.stub!(:stat).and_return(double('stat', :mode => "0600".to_i(8)))
      FakeFS::FileUtils.stub!(:chmod)
      FakeFS::File.stub!(:readlines) do |path|
        File.read(path).split("\n").map {|line| "#{line}\n"}
      end

      FileUtils.mkdir_p(@cli.netrc_path.split("/")[0..-2].join("/"))

      File.open(@cli.netrc_path, "w") do |file|
        file.puts("machine api.mortardata.com\n  login user\n  password pass\n")
      end
    end

    after do
      FileUtils.rm_rf(@cli.netrc_path)
      FakeFS.deactivate!
    end

    it "asks for credentials when the file doesn't exist" do
      @cli.delete_credentials
      @cli.should_receive(:ask_for_credentials).and_return(["u", "p"])
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.user.should == 'u'
      @cli.password.should == 'p'
    end

    it "writes credentials and uploads authkey when credentials are saved" do
      @cli.stub!(:credentials)
      @cli.stub!(:check)
      @cli.stub!(:ask_for_credentials).and_return("username", "apikey")
      @cli.should_receive(:write_credentials)
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.ask_for_and_save_credentials
    end

    it "save_credentials deletes the credentials when the upload authkey is unauthorized" do
      @cli.stub!(:write_credentials)
      @cli.stub!(:retry_login?).and_return(false)
      @cli.stub!(:ask_for_credentials).and_return("username", "apikey")
      @cli.stub!(:check) { raise Mortar::API::Errors::Unauthorized.new("Login Failed", Excon::Response.new) }
      @cli.should_receive(:delete_credentials)
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "asks for login again when not authorized, for three times" do
      @cli.stub!(:read_credentials)
      @cli.stub!(:write_credentials)
      @cli.stub!(:delete_credentials)
      @cli.stub!(:ask_for_credentials).and_return("username", "apikey")
      @cli.stub!(:check) { raise Mortar::API::Errors::Unauthorized.new("Login Failed", Excon::Response.new) }
      @cli.should_receive(:ask_for_credentials).exactly(3).times
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "writes the login information to the credentials file for the 'mortar login' command" do
      @cli.stub!(:ask_for_credentials).and_return(['one', 'two'])
      @cli.stub!(:check)
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.reauthorize
      Netrc.read(@cli.netrc_path)["api.#{@cli.host}"].should == (['one', 'two'])
    end
  end
end
