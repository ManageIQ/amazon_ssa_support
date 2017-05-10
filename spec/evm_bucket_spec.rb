require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::EvmBucket do
  before(:each) do
    $log = mocked_log
    config_aws_client_stub
  end

  let(:args) do
    { :evm_bucket => 'bucket_name', :reply_prefix => 'miq_' }
  end

  it "pass when have an get method" do
    expect(described_class).to respond_to(:get)
  end

  it "pass when return Aws::S3::Bucket" do
    expect(described_class.get(args)).to be_instance_of(Aws::S3::Bucket)
  end

  it "passes when evm_bucket is specified" do
    expect { described_class.get(args) }
  end

  it "fails when evm_bucket is not specified" do
    args.delete(:evm_bucket)
    expect { described_class.get(args) }.to raise_error(ArgumentError)
  end
end
