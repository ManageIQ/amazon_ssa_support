if ENV['CI']
  require 'simplecov'
  SimpleCov.start
end

require 'amazon_ssa_support'

RSpec.configure do |config|
  config.before(:suite) do
    $log = AmazonSsaSupport::RollingS3Logger.new("/dev/null")
  end
end
