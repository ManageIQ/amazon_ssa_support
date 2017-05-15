require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::SsaQueue do
  before(:each) do
    $log = mocked_log
    config_aws_client_stub
  end

  let(:args) do
    { :ssa_bucket   => 's3_bucket',
      :extractor_id => 'instance-id' }
  end

  subject { described_class.new(args) }

  context "Parameters" do
    it "require a paramenter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "require extractor_id" do
      args.delete(:extractor_id)
      expect { described_class.new(args) }.to raise_error(ArgumentError)
    end

    it "require ssa_bucket" do
      args.delete(:ssa_bucket)
      expect { described_class.new(args) }.to raise_error(ArgumentError)
    end

    it "require ssa_bucket" do
      expect(subject.ssa_bucket_name).to be_truthy
    end

    it "require request_queue" do
      expect(subject.request_queue).to be_truthy
    end

    it "require reply_queue" do
      expect(subject.reply_queue).to be_truthy
    end

    it "require reply_prefix" do
      expect(subject.reply_prefix).to be_truthy
    end

    it "require extractor_id" do
      expect(subject.extractor_id).to be_truthy
    end

    it "require ssa_region" do
      expect(subject.ssa_region).to be_truthy
    end

    it "require sqs" do
      expect(subject.sqs).to be_instance_of(Aws::SQS::Resource)
    end

    it "get request queue" do
      expect(subject.request_queue).to be_instance_of(Aws::SQS::Queue)
    end

    it "get reply queue" do
      expect(subject.reply_queue).to be_instance_of(Aws::SQS::Queue)
    end

    it "get reply bucket" do
      expect(subject.reply_bucket).to be_instance_of(Aws::S3::Bucket)
    end
  end
end
