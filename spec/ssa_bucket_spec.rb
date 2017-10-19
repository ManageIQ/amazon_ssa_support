require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::SsaBucket do
  before(:each) do
    config_aws_client_stub
  end

  let(:args) do
    { :ssa_bucket => 'bucket_name', :region => 'us-region' }
  end

  it "pass when have an get method" do
    expect(described_class).to respond_to(:get)
  end

  it "pass when return Aws::S3::Bucket" do
    expect(described_class.get(args)).to be_instance_of(Aws::S3::Bucket)
  end

  it "passes when ssa_bucket is specified" do
    expect { described_class.get(args) }
  end

  it "fails when ssa_bucket is not specified" do
    args.delete(:ssa_bucket)
    expect { described_class.get(args) }.to raise_error(ArgumentError)
  end

  it "fails when region is not specified" do
    args.delete(:region)
    expect { described_class.get(args) }.to raise_error(ArgumentError)
  end
end
