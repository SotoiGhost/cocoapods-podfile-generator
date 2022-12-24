# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cocoapods-podfile-generator/version.rb'

Gem::Specification.new do |spec|
  spec.name          = 'cocoapods-podfile-generator'
  spec.version       = CocoapodsPodfileGenerator::VERSION
  spec.authors       = ['Israel Soto']
  spec.email         = ['israel.spgh@gmail.com']
  spec.summary       = CocoapodsPodfileGenerator::SUMMARY
  spec.description   = CocoapodsPodfileGenerator::DESCRIPTION
  spec.homepage      = 'https://github.com/EXAMPLE/cocoapods-podfile-generator'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'json', '~> 2.6'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
