source 'https://rubygems.org'

# Specify your gem's dependencies in amazon_ssa_support.gemspec
gemspec

gem "handsoap", "=0.2.5.5", :require => false, :source => "https://rubygems.manageiq.org"
gem "manageiq-gems-pending", :git => "https://github.com/ManageIQ/manageiq-gems-pending.git", :branch => "radjabov"

minimum_version =
  case ENV['TEST_RAILS_VERSION']
  when "6.1"
    "~>6.1.7"
  when "7.0"
    "~>7.0.8"
  else
    "~>7.1.4"
  end

gem "activesupport", minimum_version
