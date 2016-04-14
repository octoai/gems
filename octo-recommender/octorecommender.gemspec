require File.expand_path('../lib/octorecommender/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'octorecommender'
  s.version     = Octo::Recommenders::VERSION

  s.summary     = "Octo Recommender(s) Module"
  s.description = <<DESC
  Contains recommendation specific stuff
DESC

  s.authors     = ["Pranav Prakash"]
  s.email       = 'pp@octo.ai'
  s.files       = Dir['lib/**/*.rb', 'spec/**/*.rb', '[A-Z]*']

  s.homepage    =
      'http://phab.octo.ai/diffusion/GEMS/'
  s.license       = 'MIT'

  s.has_rdoc    = true
  s.extra_rdoc_files = 'README.md'

  s.required_ruby_version = '>= 2.0'

  s.add_runtime_dependency 'predictor', '~> 2.3.1', '>= 2.3.0'
  s.add_runtime_dependency 'octocore', '~> 0.0.1', '>= 0.0.1'

end