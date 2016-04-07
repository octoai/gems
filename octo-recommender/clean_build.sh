rm *.gem
gem build octorecommender.gemspec && gem uninstall octorecommender && gem install octorecommender-0.0.1.gem
