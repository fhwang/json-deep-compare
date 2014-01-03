# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json-deep-compare'

Gem::Specification.new do |spec|
  spec.name          = "json-deep-compare"
  spec.version       = JsonDeepCompare::VERSION
  spec.authors       = ["Francis Hwang"]
  spec.email         = ["sera@fhwang.net"]
  spec.description   = %q{For quickly finding differences between two large JSON documents.}
  spec.summary       = %q{For quickly finding differences between two large JSON documents.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
