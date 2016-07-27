#!/bin/bash

# Remove any existing gem present
rm *.gem

# Build the gem
gem build octocore.gemspec && gem uninstall octocore --force


# Install it
find . -name "*.gem" | xargs gem install
