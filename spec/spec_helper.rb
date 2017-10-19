if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

$LOAD_PATH.unshift File.expand_path("../../lib", __FILE__)

require 'bundler/setup'
require 'amazon_ssa_support'

RSpec.configure do |config|
  config.before(:suite) do
    $log = AmazonSsaSupport::RollingS3Logger.new("/dev/null")
  end
end
