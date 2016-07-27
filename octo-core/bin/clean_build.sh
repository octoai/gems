rm *.gem
gem build octocore.gemspec && gem uninstall octocore --force
