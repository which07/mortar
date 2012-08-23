require "spec_helper"
require "mortar/command/generator"
require "FileUtils"
require "tmpdir"

describe Mortar::Command::Generate do

  # Not using FakeFS becuase it doesn't handle copying files from the 
  # real filesystem to the fake one easily. Instead using tmp directory
  # and making sure to clean up after.

  before do
    @tmpdir = Dir.mktmpdir
    Dir.chdir(@tmpdir)
  end

  after do
    FileUtils.rm_rf(@tmpdir)
  end

  describe "generate:application" do
    it "creates new project" do
      stderr, stdout = execute("generate:application Test")
      File.exists?("Test").should be_true
      File.exists?("Test/macros").should be_true
      File.exists?("Test/pigscripts").should be_true
      File.exists?("Test/udfs").should be_true
      File.exists?("Test/Gemfile").should be_true
      #File.exists?("Test/Gemfile.lock").should be_true
      File.exists?("Test/macros/.gitkeep").should be_true
      File.exists?("Test/pigscripts/Test.pig").should be_true
      File.exists?("Test/udfs/python/Test.py").should be_true
    end
  end

  describe "new" do
    it "create new project using alias" do
      FileUtils.rm_rf("Test")
      stderr, stdout = execute("new Test")
      File.exists?("Test").should be_true
      File.exists?("Test/macros").should be_true
      File.exists?("Test/pigscripts").should be_true
      File.exists?("Test/udfs").should be_true
      File.exists?("Test/Gemfile").should be_true
      #File.exists?("Test/Gemfile.lock").should be_true
      File.exists?("Test/macros/.gitkeep").should be_true
      File.exists?("Test/pigscripts/Test.pig").should be_true
      File.exists?("Test/udfs/python/Test.py").should be_true
    end
  end

  describe "generate:pigscript" do
    it "Generate a new pigscript in a project" do
      with_blank_project do |p| 
        stderr, stdout = execute("generate:pigscript Oink", p)
        File.exists?(File.join(p.root_path, "pigscripts/Oink.pig"))
      end
    end
  end

  describe "generate:python_udf" do
    it "Generate a new python udf in a project" do
      with_blank_project do |p| 
        stderr, stdout = execute("generate:python_udf slither", p)
        File.exists?(File.join(p.root_path, "udfs/python/slither.py"))
      end
    end
  end

  describe "generate:macro" do
    it "Generate a new macro in a project" do
      with_blank_project do |p| 
        stderr, stdout = execute("generate:macro big_mac", p)
        File.exists?(File.join(p.root_path, "macros/big_mac.py"))
      end
    end
  end
end