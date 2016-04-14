#!/bin/bash
#
# Build all gems
#
#
#

specs=( "octo-core" "octo-recommender" "octo-newsfeed" )

for spec in ${specs[@]}; do
  echo "Building gem $spec"
  cd $spec
  rm *.gem
  gemspec=`find . -name '*.gemspec'`
  gem build $gemspec

  gemname=`find . -name '*.gem'`
  gem install $gemname
  cd ..
done
