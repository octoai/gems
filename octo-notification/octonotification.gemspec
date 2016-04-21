require File.expand_path('../lib/octonotification/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'octonotification'
  s.version     = Octo::Notification::VERSION

  s.summary     = 'Octo Notification(s) Module'
  s.description = <<DESC
  Contains notifications specific stuff
DESC

  s.authors     = ['Ravin Gupta']
  s.email       = 'ravin.gupta@octo.ai'
  s.files       = Dir['lib/**/*.rb', 'spec/**/*.rb', '[A-Z]*']

  s.homepage    =
      'https://bitbucket.org/auroraborealisinc/gems'
  s.license       = 'MIT'

  s.has_rdoc    = true
  s.extra_rdoc_files = 'README.md'

  s.required_ruby_version = '>= 2.0'

  s.add_runtime_dependency 'octorecommender', '~> 0.0.1', '>= 0.0.1'
  s.add_runtime_dependency 'gcm', '~> 0.1.1', '>= 0.1.0'
  s.add_runtime_dependency 'apns', '~> 1.0.0', '>= 1.0.0'
  s.add_runtime_dependency 'aws-sdk', '~> 2.2.35', '>= 2.2.35'
end