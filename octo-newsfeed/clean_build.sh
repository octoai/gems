rm *.gem
gem build octonewsfeed.gemspec && gem uninstall octonewsfeed --force && gem install octonewsfeed-0.0.1.gem
