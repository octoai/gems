rm *.gem
gem build octoga.gemspec && gem uninstall octoga --force && gem install octoga-0.0.1.gem
