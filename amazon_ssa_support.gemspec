# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'amazon_ssa_support/version'

Gem::Specification.new do |spec|
  spec.name          = "amazon_ssa_support"
  spec.version       = AmazonSsaSupport::VERSION
  spec.authors       = ["ManageIQ Developers"]

  spec.summary       = %q{Supporting files and libraries for SmartState Analysis on Amazone EC2}
  spec.description   = %q{This is a ruby interface for SSA on Amazon EC2 instances and images}
  spec.homepage      = "https://github.com/ManageIQ/amazon_ssa_support"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) } - %w[console setup]
  spec.require_paths = ["lib"]

  spec.add_dependency "aws-sdk", "~>2.9.7"
  spec.add_dependency "manageiq-gems-pending", "~> 0"
  spec.add_dependency "manageiq-smartstate", "~> 0.1"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_development_dependency "codeclimate-test-reporter", "~> 1.0.0"
  spec.add_development_dependency "simplecov"
end
