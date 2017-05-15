require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::SsaHeartbeat do
  before(:each) do
    $log = mocked_log
    Aws.config[:s3] = {
      :stub_responses => {
        :list_buckets => { :buckets => [{ :name => 'miq_test' }] }
      }
    }
  end

  let(:args) do
    { :extractor_id       => 'instance_id',
      :ssa_bucket         => 'bucket',
      :reply_prefix       => 'rep-prefix',
      :heartbeat_prefix   => 'hb-prefix',
      :heartbeat_thread   => 'hb-thread',
      :heartbeat_interval => 'hb-interval' }
  end

  subject { described_class.new(args) }

  context "Parameters" do
    it "require a parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "passes if an ArgumentError is raised when extractor_id is not specified." do
      args.delete(:extractor_id)
      expect { described_class.new(args) }.to raise_error(ArgumentError)
    end

    it "require heartbeat_prefix" do
      expect(subject.heartbeat_prefix).to eq("hb-prefix")
    end
  end
end
