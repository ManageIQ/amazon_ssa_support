#require 'aws-sdk'
require "spec_helper"

describe AmazonSsaSupport do
  it "has a version number" do
    expect(AmazonSsaSupport::VERSION).not_to be nil
  end

end
