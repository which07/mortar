# Mortar Development Framework

[Mortar](http://www.mortardata.com/) is a platform as a service for Hadoop. With Mortar, you can run jobs on Hadoop using Apache Pig and Python without any special training.

The Mortar Development Framework lets you develop Mortar Hadoop jobs directly on your local computer without installing any Hadoop libraries.  Lots more info can be found on the [Mortar help site](http://help.mortardata.com).  

[![Build Status](https://travis-ci.org/mortardata/mortar.png?branch=master)](https://travis-ci.org/mortardata/mortar) [![Dependency Status](https://gemnasium.com/mortardata/mortar.png)](https://gemnasium.com/mortardata/mortar)

# Setup

## Dependencies

* [Git](http://git-scm.com/downloads) 1.7.7 or later
* [Ruby](http://www.ruby-lang.org/en/downloads/) 1.8.7 or later
* [Gem](https://rubygems.org/pages/download) (included with Ruby 1.9.2+)

## Installation

    gem install mortar

# Development

To develop on the gem, install the bundle, and then use bundle exec to run mortar:

    gem install bundler
    bundle install
    bundle exec mortar <command> <args>

# Tests

You can run all the RSpec tests with rake:

    rake spec

To run tests for a single file using:

    rspec path/to/test_file
