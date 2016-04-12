rm *.gem
gem build octocore.gemspec && gem uninstall octocore --force && gem install octocore-0.0.1.gem
