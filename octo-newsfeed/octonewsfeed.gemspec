require File.expand_path('../lib/octonewsfeed/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'octonewsfeed'
  s.version     = Octo::NewsFeed::VERSION
  s.date        = '2016-03-19'
  s.summary     = 'All things newsfeed'
  s.description = 'Components needed for a newsfeed'
  s.authors     = %w(PranavPrakash)
  s.email       = 'pp@octo.ai'
  s.files       = Dir['lib/**/*.rb', 'spec/**/*.rb', '[A-Z]*']
  s.homepage    =
    'http://phab.octo.ai/diffusion/GEMS/'
  s.license       = 'MIT'
  s.has_rdoc    = true
  s.extra_rdoc_files = 'README.md'

  s.required_ruby_version = '>= 2.0'

  s.add_runtime_dependency 'octorecommender', '~> 0.0.1', '>=0.0.1'

end

