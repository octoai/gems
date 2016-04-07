#!/bin/bash
#
# Build all gems
#
#
#

specs=`find . -type d \( ! -name . \) -maxdepth 1 -not -name ".*" | sort -n`

for spec in $specs; do
  echo "Building gem $spec"
  cd $spec
  gemspec=`find . -name '*.gemspec'`
  gem build $gemspec

  gemname=`find . -name '*.gem'`
  gem install $gemname
  cd ..
done
