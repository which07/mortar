require "spec_helper"
require "mortar/helpers"

module Mortar
  describe Helpers do
    include Mortar::Helpers

    context "display_object" do

      it "should display Array correctly" do
        capture_stdout do
          display_object([1,2,3])
        end.should == <<-OUT
1
2
3
OUT
      end

      it "should display { :header => [] } list correctly" do
        capture_stdout do
          display_object({:first_header => [1,2,3], :last_header => [7,8,9]})
        end.should == <<-OUT
=== first_header
1
2
3

=== last_header
7
8
9

OUT
      end

      it "should display String properly" do
        capture_stdout do
          display_object('string')
        end.should == <<-OUT
string
OUT
      end

    end
    
    context "write_to_file" do
      it "should write data to a directory that does not yet exist" do
        
        # use FakeFS file system
        include FakeFS::SpecHelpers
        
        filepath = File.join(Dir.tmpdir, "my_new_dir", "my_new_file.txt")
        data = "foo\nbar"
        write_to_file(data, filepath)
        File.exists?(filepath).should be_true
        infile = File.open(filepath, "r")
        infile.read.should == data
        infile.close()
      end
    end
  end
end
