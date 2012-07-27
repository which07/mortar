require "spec_helper"
require "mortar/command/base"

module Mortar::Command
  describe Base do
    before do
      @base = Base.new
      @base.stub!(:display)
      @client = mock('mortar client', :host => 'mortar.com')
    end

    context "detecting the project" do
      it "attempts to find the project via the --project option" do
        @base.stub!(:options).and_return(:project => "myproject")
        @base.project.name.should == "myproject"
      end

      it "attempts to find the project via MORTAR_PROJECT when not explicitly specified" do
        ENV['MORTAR_PROJECT'] = "myenvproject"
        @base.project.name.should == "myenvproject"
        @base.stub!(:options).and_return([])
        @base.project.name.should == "myenvproject"
        ENV.delete('MORTAR_PROJECT')
      end

      it "overrides MORTAR_PROJECT when explicitly specified" do
        ENV['MORTAR_PROJECT'] = "myenvproject"
        @base.stub!(:options).and_return(:project => "myproject")
        @base.project.name.should == "myproject"
        ENV.delete('MORTAR_PROJECT')
      end

      it "read remotes from git config" do
        Dir.stub(:chdir)
        File.should_receive(:exists?).with(".git").and_return(true)
        @base.should_receive(:git).with('remote -v').and_return(<<-REMOTES)
staging\tgit@github.com:mortarcode/myproject-staging.git (fetch)
staging\tgit@github.com:mortarcode/myproject-staging.git (push)
production\tgit@github.com:mortarcode/myproject.git (fetch)
production\tgit@github.com:mortarcode/myproject.git (push)
other\tgit@github.com:other.git (fetch)
other\tgit@github.com:other.git (push)
        REMOTES

        @mortar = mock
        @mortar.stub(:host).and_return('mortar.com')
        @base.stub(:mortar).and_return(@mortar)

        # need a better way to test internal functionality
        @base.send(:git_remotes, '/home/dev/myproject').should == { 'staging' => 'myproject-staging', 'production' => 'myproject' }
      end

      it "gets the project from remotes when there's only one project" do
        @base.stub!(:git_remotes).and_return({ 'mortar' => 'myproject' })
        @base.stub!(:git).with("config mortar.remote").and_return("")
        @base.project.name.should == 'myproject'
      end

      it "accepts a --remote argument to choose the project from the remote name" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'myproject-staging', 'production' => 'myproject' })
        @base.stub!(:options).and_return(:remote => "staging")
        @base.project.name.should == 'myproject-staging'
      end

      it "raises when cannot determine which project is it" do
        @base.stub!(:git_remotes).and_return({ 'staging' => 'myproject-staging', 'production' => 'myproject' })
        lambda { @base.project }.should raise_error(Mortar::Command::CommandFailed)
      end
    end

  end
end
