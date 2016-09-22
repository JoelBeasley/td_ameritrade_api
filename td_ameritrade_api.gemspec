# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'td_ameritrade_api/version'

Gem::Specification.new do |spec|
  spec.name          = 'td_ameritrade_api'
  spec.version       = TDAmeritradeAPI::VERSION
  spec.authors       = ['Kevin Pheasey']
  spec.email         = ['kevin@kpheasey.com']

  spec.summary       = %q{TD Ameritrade API wrapper}
  spec.description   = %q{TD Ameritrade API wrapper for interfacing with advisor file downloads}
  spec.homepage      = 'https://github.com/JoelBeasley/td_ameritrade_api'


  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.13'
  spec.add_development_dependency 'rake', '~> 10.0'
end
