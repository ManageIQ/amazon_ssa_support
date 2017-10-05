source 'https://rubygems.org'

# Specify your gem's dependencies in amazon_ssa_support.gemspec
gemspec

gem "log_decorator", "~>0.1.0", :require => 'log_decorator'
gem "manageiq-gems-pending", ">0", :require => 'manageiq-gems-pending', :git => "https://github.com/ManageIQ/manageiq-gems-pending.git", :branch => "master"
gem "manageiq-smartstate", "~>0.1.5", :require => 'manageiq-smartstate'
gem "rake"

group :test do
  gem "handsoap", "~>0.2.5", :require => false, :git => "https://github.com/ManageIQ/handsoap.git", :tag => "v0.2.5-5"
end
