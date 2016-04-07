Gem::Specification.new do |s|
  s.name        = 'newsfeed'
  s.version     = '0.0.1'
  s.date        = '2016-03-19'
  s.summary     = "Newsfeed Interfaces"
  s.description = "Provides ruby interfaces to the Newsfeed"
  s.authors     = ["Pranav Prakash"]
  s.email       = 'pp@octo.ai'
  s.files       = ["lib/feed.rb"]
  s.homepage    =
    'https://bitbucket.org/auroraborealisinc/gems'
  s.license       = 'MIT'

  s.add_runtime_dependency 'octorecommender', '~> 0.0.1', '>=0.0.1'

end

