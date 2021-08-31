require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--options #{File.expand_path(".rspec_ci", __dir__)}" if ENV['CI']
end

task :default => :spec

Dir.glob(File.expand_path("lib/tasks/*", __dir__)).sort.each { |f| load f }
