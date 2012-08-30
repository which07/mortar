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
# Portions of this code from heroku (https://github.com/heroku/heroku/) Copyright Heroku 2008 - 2012,
# used under an MIT license (https://github.com/heroku/heroku/blob/master/LICENSE).
#

module DisplayMessageMatcher

  def display_message(command, message)
    DisplayMessageMatcher::DisplayMessage.new command, message
  end

  class DisplayMessage
    def initialize(command, message)
      @command = command
      @message = message
    end

    def matches?(given_proc)
      displayed_expected_message = false
      @given_messages = []

      @command.should_receive(:display).
        any_number_of_times do |message, newline|
        @given_messages << message
        displayed_expected_message = displayed_expected_message ||
          message == @message
      end

      given_proc.call

      displayed_expected_message
    end

    def failure_message
      "expected #{ @command } to display the message #{ @message.inspect } but #{ given_messages }"
    end

    def negative_failure_message
      "expected #{ @command } to not display the message #{ @message.inspect } but it was displayed"
    end

    private

      def given_messages
        if @given_messages.empty?
          'no messages were displayed'
        else
          formatted_given_messages = @given_messages.map(&:inspect).join ', '
          "the follow messages were displayed: #{ formatted_given_messages }"
        end
      end

  end
end
