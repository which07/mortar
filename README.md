# Mortar CLI

The Mortar CLI lets you run Hadoop jobs on the Mortar service.

# Setup

## Ruby

First, install [rvm](https://rvm.io/rvm/install/).

        curl -kL https://get.rvm.io | bash -s stable
        
Afterward, add the line recommended by rvm to your bash initialization file.

Then, switch to the directory where you've cloned mortar.  If you don't have the right version of Ruby installed, you will be prompted to upgrade via rvm.

## Dependencies

Install required gems:

        bundle install

# Running

You can run the command line through bundle:

        bundle exec mortar <command> <args>
        
        # example
        bundle exec mortar help

# Testing

To run the tests, do:

        rake spec
