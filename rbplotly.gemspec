# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'plotly/version'

Gem::Specification.new do |spec|
  spec.name          = 'rbplotly'
  spec.version       = Plotly::VERSION
  spec.authors       = ['ash1day']
  spec.email         = ['y4ashida@gmail.com']

  spec.summary       = 'a Ruby visualization library'
  spec.description   = 'Rbplotly, a Ruby visualization library, ' \
                       'allows you to create interactive plots.'
  spec.homepage      = 'https://github.com/y4ashida/rbplotly'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday',   '~> 0.9'
  spec.add_dependency 'uuidtools', '~> 2.1'
  spec.add_dependency 'launchy',   '~> 2.4'

  spec.add_development_dependency 'bundler',       '~> 2.0.0'
  spec.add_development_dependency 'guard-rspec',   '~> 4.7'
  spec.add_development_dependency 'rake',          '~> 11.2'
  spec.add_development_dependency 'rspec',         '~> 3.5'
  spec.add_development_dependency 'yard',          '~> 0.9'

  spec.add_development_dependency 'codeclimate-test-reporter', '~> 0.6'
end
