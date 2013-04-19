#!/bin/bash

set -e

export PIG_HOME=<%= @pig_home %>
export PIG_CLASSPATH=<%= @pig_classpath %>
export CLASSPATH=<%= @classpath %>

# Setup python environment, needed for udf's that might be run
source <%= @local_install_dir %>/pythonenv/bin/activate

# Run Pig
<%= @local_install_dir %>/jython/bin/jython \
<% @java_props.each do |k,v| %> -D<%= k %>=<%= v %> \
<% end %> <% @jython_cmd_parts.each do |v| %> "<%= v %>" <% end %>
