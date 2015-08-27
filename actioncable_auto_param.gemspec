# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'actioncable_auto_param/version'

Gem::Specification.new do |spec|
  spec.name          = "actioncable_auto_param"
  spec.version       = ActioncableAutoParam::VERSION
  spec.authors       = ["Mike A. Owens"]
  spec.email         = ["mike@meter.md"]

  spec.summary       = %q{Automatically extracts ActionCable objects into parameters}
  spec.homepage      = "https://github.com/metermd/actioncable_auto_param"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "actioncable", "~> 0.0.3"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest"
end
