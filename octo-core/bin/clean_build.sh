rm *.gem
gem build octocore.gemspec && gem uninstall octocore && gem install octocore-0.0.1.gem
