#!/bin/bash

set -e

export PIG_HOME=<%= @pig_home %>
export PIG_CLASSPATH=<%= @pig_classpath %>
export CLASSPATH=<%= @classpath %>
export PIG_MAIN_CLASS=com.mortardata.hawk.HawkMain
export PIG_OPTS="-Dfs.s3n.awsAccessKeyId=<%= @AWS_ACCESS_KEY %> -Dfs.s3n.awsSecretAccessKey=<%= @AWS_SECRET_KEY %>"

# UDF paths are relative to this direectory
cd <%= @project_home %>/pigscripts

# Setup python environment
source <%= @local_install_dir %>/pythonenv/bin/activate

# Run Pig
<%= @local_install_dir %>/pig/bin/pig -exectype local \
    -log4jconf <%= @local_install_dir %>/pig/properties/log4j.properties \
    -propertyFile <%= @local_install_dir %>/pig/properties/pig.properties \
    <% @pig_params.each do |param| %>-param <%= param['name'] %>=<%= param['value'] %> <% end %>\
    <%= @pig_sub_command %> 


