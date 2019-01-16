# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'gush/control/version'

Gem::Specification.new do |spec|
  spec.name          = "gush-control"
  spec.version       = Gush::Control::VERSION
  spec.authors       = ["Michal Krzyzanowski"]
  spec.email         = ["michal.krzyzanowski+github@gmail.com"]
  spec.summary       = "Web GUI for controlling Gush workflows"
  spec.description   = spec.summary
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sinatra"
  spec.add_runtime_dependency "thin"
  spec.add_runtime_dependency "tilt"
  spec.add_runtime_dependency "gush"
  spec.add_runtime_dependency "slim"
  spec.add_runtime_dependency "coffee-script"
  spec.add_runtime_dependency "sinatra-websocket"
  spec.add_runtime_dependency "sprockets"

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "capybara-webkit"
end
