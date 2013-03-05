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

require 'zlib'
require 'excon'
require 'rbconfig'
require 'rubygems/package'

require 'mortar/helpers'

module Mortar
  module Local
    module InstallUtil

      include Mortar::Helpers

      def local_install_directory
        # note: assumes that CWD is the project root, is
        # this a safe assumption?
        File.join(Dir.getwd, "/.mortar-local")
      end


      # Drops a marker file for an installed package, used
      # to help determine if updates should be performed
      def note_install(subdirectory)
        install_file = install_file_for(subdirectory)
        File.open(install_file, "w") do |install_file|
          # Write out the current epoch so we know when this
          # dependency was installed
          install_file.write("#{Time.now.to_i}\n")
        end
      end

      def install_date(subsection)
        install_file = install_file_for(subsection)
        if File.exists?(install_file)
          File.open(install_file, "r") do |f|
            file_contents = f.read()
            file_contents.strip.to_i
          end
        end
      end

      def install_file_for(subdirectory)
        File.join(local_install_directory, subdirectory, "install-date.txt")
      end

      # Given a path to a foo.tgz or foo.tar.gz file, extracts its
      # contents to the specified output directory
      def extract_tgz(tgz_path, dest_dir)
        FileUtils.mkdir_p(dest_dir)
        Gem::Package::TarReader.new(Zlib::GzipReader.open(tgz_path)).each do |entry|
          entry_path = File.join(dest_dir, entry.full_name)
          if entry.directory?
            FileUtils.mkdir_p(entry_path)
          elsif entry.file?
            File.open(entry_path, "wb") do |entry_file|
              entry_file.write(entry.read)
            end
          end
        end
      end

      # Downloads the file at a specified url into the supplied director
      def download_file(url, dest_dir)
        dest_file_path = dest_dir + "/" + File.basename(url)
        File.open(dest_file_path, "wb") do |dest_file|
          contents = Excon.get(url).body
          dest_file.write(contents)
        end
      end

      def osx?
        os_platform_name = RbConfig::CONFIG['target_os']
        return os_platform_name.start_with?('darwin')
      end

      # Given an environment variable and a default value return
      # the environment variable if specified, otherwise the default
      def env_or_default(env_var, default)
        if ENV[env_var].to_s != ""
          return ENV[env_var]
        else
          return default
        end
      end

    end
  end
end
