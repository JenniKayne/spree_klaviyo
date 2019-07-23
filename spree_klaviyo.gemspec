lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'spree_klaviyo/version'

# encoding: UTF-8
Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.name        = 'spree_klaviyo'
  s.version     = SpreeKlaviyo::VERSION
  s.summary     = 'Spree-klaviyo Integration'
  s.description = 'Manages and syncronises klaviyo subscribers'
  s.required_ruby_version = '>= 2.1.0'

  s.email         = ["bfscordeiro@gmail.com"]
  s.authors       = ["Bruno Frank"]
  s.homepage      = "http://www.jennikayne.com/"
  s.license       = 'BSD-3'

  s.files         = `git ls-files`.split("\n")
  s.require_path  = 'lib'
  s.requirements << 'none'

  s.add_dependency 'spree_core', '>= 3.1.0', '< 4.0'
  s.add_dependency 'httparty'
  s.add_dependency 'sentry-raven'

  s.add_development_dependency 'rspec-rails', '~> 3.4'
  s.add_development_dependency 'sinatra'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'byebug'
end
