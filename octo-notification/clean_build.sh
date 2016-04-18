rm *.gem
gem build octonotification.gemspec && gem uninstall octonotification --force && gem install octonotification-0.0.1.gem