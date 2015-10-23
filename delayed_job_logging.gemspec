# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "delayed_job_logging/version"

Gem::Specification.new do |spec|
  spec.name          = "delayed_job_logging"
  spec.version       = DelayedJobLogging::VERSION
  spec.authors       = ["Johannes Barre"]
  spec.email         = ["igel@igels.net"]

  spec.summary       = "Provides a module, which logs useful stuff about your Delayed Jobs in JSON format"
  spec.homepage      = "https://github.com/Savedo/delayed_job_logging"
  spec.license       = "MIT"

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.1"

  spec.add_runtime_dependency "delayed_job", "~> 4.0"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"

  spec.add_development_dependency "delayed_job_active_record", "~> 4.0"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "sqlite3"
end
