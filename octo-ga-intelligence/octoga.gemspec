require File.expand_path('../lib/octoga/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'octoga'
  s.version     = Octo::GA::VERSION

  s.summary     = 'Octo\'s intelligence for Google Analytics (GA)'
  s.description = <<DESC
Octo's ingelligence when applied to Google Analytics can produce
great meaningful insights. This gem drives all of that.
DESC

  s.authors     = ['Pranav Prakash']
  s.email       = 'pp@octo.ai'
  s.files       = Dir['lib/**/*.rb', 'spec/**/*.rb', '[A-Z]*', 'lib/**/*.yml']

  s.executables << 'ga_analysis'

  s.homepage    =
    'http://phab.octo.ai/diffusion/GEMS/'
  s.license       = 'MIT'

  s.has_rdoc    = true
  s.extra_rdoc_files = 'README.md'

  s.required_ruby_version = '>= 2.0'

  s.add_runtime_dependency 'cequel',  '~> 1.9', '>= 1.9.0'
  s.add_runtime_dependency 'redis', '~> 3.2.2', '>= 3.2.0'
  s.add_runtime_dependency 'hiredis', '~> 0.6.1', '>= 0.6.0'
  s.add_runtime_dependency 'rake', '~> 11.1.0', '>= 11.1.0'
  s.add_runtime_dependency 'sinatra',  '~> 1.4.7', '>= 1.4.7'
  s.add_runtime_dependency 'legato',  '~> 0.7.0', '>= 0.7.0'
  s.add_runtime_dependency 'oauth2',  '~> 1.1.0', '>= 1.1.0'
  s.add_runtime_dependency 'activesupport', '~> 4.2.6', '>= 4.2.6'
  s.add_runtime_dependency 'smarter_csv', '~> 1.1.0', '>= 1.1.0'
  s.add_runtime_dependency 'ai4r', '~> 1.13', '>= 1.13'
  s.add_runtime_dependency 'gnuplot', '~> 2.6.2', '>= 2.6.2'
  s.add_runtime_dependency 'descriptive_statistics', '~> 2.5.1', '>= 2.5.1'

  s.add_development_dependency 'rspec', '~> 3.4.0', '>= 3.4.0'
  s.add_development_dependency 'parallel_tests', '~> 2.5.0', '>= 2.5.0'
end

