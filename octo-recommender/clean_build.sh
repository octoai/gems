rm *.gem
gem build octorecommender.gemspec && gem uninstall octorecommender --force && gem install octorecommender-0.0.1.gem
