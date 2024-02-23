# AmazonSsaSupport

[![Gem Version](https://badge.fury.io/rb/amazon_ssa_support.svg)](http://badge.fury.io/rb/amazon_ssa_support)
[![CI](https://github.com/ManageIQ/amazon_ssa_support/actions/workflows/ci.yaml/badge.svg?branch=radjabov)](https://github.com/ManageIQ/amazon_ssa_support/actions/workflows/ci.yaml)
[![Code Climate](https://codeclimate.com/github/ManageIQ/amazon_ssa_support.svg)](https://codeclimate.com/github/ManageIQ/amazon_ssa_support)
[![Test Coverage](https://codeclimate.com/github/ManageIQ/amazon_ssa_support/badges/coverage.svg)](https://codeclimate.com/github/ManageIQ/amazon_ssa_support/coverage)

[![Chat](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/ManageIQ/amazon_ssa_support?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

This gem provides support required for running ManageIQ Smart State Analysis (SSA) on Amazon Instances and Images.
There are two use cases in which the gem is used: when running in AWS as an agent, the scanning instance installs the gem to perform SSA on Instances and Images attached to it; on a ManageIQ appliance, the gem is used to issue requests for SSA and handle the responses.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'amazon_ssa_support'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install amazon_ssa_support

## Usage

To queue an SSA Extract Request:

    ssaq_args                 = {}
    ssaq_args[:ssa_bucket]    = bucket_name
    ssaq_args[:region]        = region_name
    ssaq_args[:sqs]           = connected_sqs_service
    ssaq_args[:s3]            = connected_s3_service
    ssaq = AmazonSsaSupport::SsaQueue.new(ssaq_args)
    ssaq.send_extract_request(ems_reference, job_id, AmazonSsaSupport::SsaExtractor::CATEGORIES)

To obtain the SSA Extract Response:

    reply = ssaq.reply_loop

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/manageiq/amazon_ssa_support. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
