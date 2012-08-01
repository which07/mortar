require "spec_helper"
require "mortar/auth"
require "mortar/helpers"

module Mortar
  describe Auth do
    include Mortar::Helpers

    before do
      ENV['MORTAR_API_KEY'] = nil
      
      @cli = Mortar::Auth
      stub(@cli).check
      stub(@cli).display
      stub(@cli).running_on_a_mac? {false}
      @cli.credentials = nil

      FakeFS.activate!
      
      stub(my_mode_output = Object.new).mode {"0600".to_i(8)}
      stub(FakeFS::File).stat {my_mode_output}
      stub(FakeFS::FileUtils).chmod
      stub(FakeFS::File).readlines do |path|
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
      mock(@cli).ask_for_credentials {["u", "p"]}
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.user.should == 'u'
      @cli.password.should == 'p'
    end

    it "writes credentials and uploads authkey when credentials are saved" do
      stub(@cli).credentials
      stub(@cli).check
      stub(@cli).ask_for_credentials.returns("username", "apikey")
      mock(@cli).write_credentials
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.ask_for_and_save_credentials
    end

    it "save_credentials deletes the credentials when the upload authkey is unauthorized" do
      stub(@cli).write_credentials
      stub(@cli).retry_login? { false }
      stub(@cli).ask_for_credentials.returns("username", "apikey")
      stub(@cli).check { raise Mortar::API::Errors::Unauthorized.new("Login Failed", Excon::Response.new) }
      mock.proxy(@cli).delete_credentials
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "asks for login again when not authorized, for three times" do
      stub(@cli).read_credentials
      stub(@cli).write_credentials
      stub(@cli).delete_credentials
      #stub(@cli).ask_for_credentials.returns("username", "apikey")
      stub(@cli).check { raise Mortar::API::Errors::Unauthorized.new("Login Failed", Excon::Response.new) }
      mock(@cli).ask_for_credentials.times(3).returns("username", "apikey")
      lambda { @cli.ask_for_and_save_credentials }.should raise_error(SystemExit)
    end

    it "writes the login information to the credentials file for the 'mortar login' command" do
      stub(@cli).ask_for_credentials.returns(['one', 'two'])
      stub(@cli).check
      #@cli.should_receive(:check_for_associated_ssh_key)
      @cli.reauthorize
      Netrc.read(@cli.netrc_path)["api.#{@cli.host}"].should == (['one', 'two'])
    end
  end
end
