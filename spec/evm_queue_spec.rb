require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::EvmQueue do

  before(:each) { $log = mocked_log }

  let(:args) do
    { :evm_bucket    => 's3_bucket',
      :extractor_id  => 'instance-id'
    }
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

    it "require evm_bucket" do
      args.delete(:evm_bucket)
      expect { described_class.new(args) }.to raise_error(ArgumentError)
    end

    it "require evm_bucket" do
      expect(subject.evm_bucket_name).to be_truthy
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

    it "require evm_region" do
      expect(subject.evm_region).to be_truthy
    end

    it "require sqs" do
      expect(subject.sqs).to be_instance_of(Aws::SQS::Resource)
    end

    it "require s3" do
      expect(subject.s3).to be_instance_of(Aws::S3::Resource)
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

  context "Request methods" do
    let(:ec_id) { "i-1234567" }
    it "send_extract_request" do
      expect(subject.send_extract_request(ec_id)).to be_truthy
    end

    it "send_exit_request" do
      expect(subject.send_exit_request(ec_id)).to be_truthy
    end

    it "send_reboot_request" do
      expect(subject.send_reboot_request(ec_id)).to be_truthy
    end

    it "send_shutdown_request" do
      expect(subject.send_shutdown_request(ec_id)).to be_truthy
    end
  end

  context "Reply methods" do
    let(:req) do
      {  request_kype: 'extract', 
         sqs_msg: { :message_id => 'msg_01' } 
      } 
    end

    #it "send_ers_reply" do
    #  expect(subject.send_ers_reply(req)).to be_truthy
    #end

  end
end
