require 'spec_helper'
require 'fakefs/spec_helpers'
require 'mortar/project'
require 'mortar/command/pigscripts'

module Mortar::Command
  describe PigScripts do
    
    # use FakeFS file system
    include FakeFS::SpecHelpers
    
    before(:each) do
      stub_core
    end
    
    context("index") do
      
      it "displays a message when no pigscripts found" do
        with_blank_project do |p|
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
You have no pigscripts.
STDOUT
        end
      end
      
      it "displays list of 1 pigscript" do
        with_blank_project do |p|
          write_file(File.join(p.pigscripts_path, "my_script.pig"))
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
=== pigscripts
my_script

STDOUT
        end
      end
      
      it "displays list of multiple pigscripts" do
        with_blank_project do |p|
          write_file(File.join(p.pigscripts_path, "a_script.pig"))
          write_file(File.join(p.pigscripts_path, "b_script.pig"))
          stderr, stdout = execute("pigscripts", p)
          stdout.should == <<-STDOUT
=== pigscripts
a_script
b_script

STDOUT
        end

      end
      
    end

    context("expand") do
      
      it "errors when no SCRIPT argument provided" do
        stderr, stdout = execute("pigscripts:expand", p)
        stderr.should == <<-STDERR
 !    Usage: mortar pigscripts:expand SCRIPT
 !    Must specify SCRIPT.
STDERR
      end
      
      it "errors when the pigscript cannot be found" do
        with_blank_project do |p|
          stderr, stdout = execute("pigscripts:expand does_not_exist", p)
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    No pigscripts found
STDERR
        end
      end
      
      it "displays the other options when a pigscript cannot be found" do
        with_blank_project do |p|
          write_file(File.join(p.pigscripts_path, "does_exist.pig"))
          stderr, stdout = execute("pigscripts:expand does_not_exist", p)
          stderr.should == <<-STDERR
 !    Unable to find pigscript does_not_exist
 !    Available scripts:
 !    does_exist
STDERR
        end
      end
      
      it "returns a pigscript without templates without modification" do
        with_blank_project do |p|
          contents = <<-PIGSCRIPT
-- My pigscript
x = LOAD 's3n://mybucket/myfile' USING PigStorage() AS (foo:chararray, bar:int);
PIGSCRIPT
          write_file(File.join(p.pigscripts_path, "pig_script.pig"), contents)
          stderr, stdout = execute("pigscripts:expand pig_script", p)
          stdout.should == contents
        end
      end
      
      it "returns a pigscript with a dataset template included" do
        with_blank_project do |p|
          songs_dataset_contents = <<-DATASET
/*
 * songs: Full set of 1MM song dataset.
 */
DEFINE SONGS_LOADER()
returns loaded {
    -- FIXME add in templating for the dataset
    $loaded =
                LOAD 's3n://tbmmsd/A.tsv.*'
                USING PigStorage('\t') AS (
                     track_id:chararray, analysis_sample_rate:chararray, artist_7digitalid:chararray);
};

DEFINE SONGS_STORER(alias)
returns void {
    STORE $alias
     INTO 's3n://fakepath/fake'
    USING PigStorage('\t');
};
DATASET
          pigscript_contents = <<-PIGSCRIPT
-- My pigscript
<%= datasets.songs.code -%>

x = SONGS_LOADER();
PIGSCRIPT
          write_file(File.join(p.datasets_path, "songs.pig"), songs_dataset_contents)
          write_file(File.join(p.pigscripts_path, "pig_script.pig"), pigscript_contents)
          stderr, stdout = execute("pigscripts:expand pig_script", p)
          stdout.should == <<-STDOUT
-- My pigscript
/*
 * songs: Full set of 1MM song dataset.
 */
DEFINE SONGS_LOADER()
returns loaded {
    -- FIXME add in templating for the dataset
    $loaded =
                LOAD 's3n://tbmmsd/A.tsv.*'
                USING PigStorage('\t') AS (
                     track_id:chararray, analysis_sample_rate:chararray, artist_7digitalid:chararray);
};

DEFINE SONGS_STORER(alias)
returns void {
    STORE $alias
     INTO 's3n://fakepath/fake'
    USING PigStorage('\t');
};

x = SONGS_LOADER();
STDOUT
        end
      end
    end
  end
end
