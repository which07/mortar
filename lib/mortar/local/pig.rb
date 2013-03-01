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

require "mortar/local/installutil"

class Mortar::Local::Pig
  include Mortar::Local::InstallUtil

  def command
    return "#{pig_directory}/bin/pig"
  end

  def pig_directory
    return local_install_directory + "/pig"
  end

  def pig_archive_url
    return env_or_default('PIG_DISTRO_URL',
                  "https://s3.amazonaws.com/mortar-public-artifacts/mortar-mud.tgz")
  end

  def pig_archive_file
    File.basename(pig_archive_url)
  end

  # Determines if a pig install needs to occur, true if no
  # pig install present or a newer version is available
  def should_do_pig_install?
    return (not (File.exists?(pig_directory)))
  end

  # Installs pig for this project if it is not already present
  def install
    if should_do_pig_install?
      FileUtils.mkdir_p(local_install_directory)
      progress_message "Installing pig" do
        download_file(pig_archive_url, local_install_directory)
        extract_tgz(local_install_directory + "/" + pig_archive_file, local_install_directory)
        File.delete(local_install_directory + "/" + pig_archive_file)
        note_install("pig")
      end
    end
  end

end
