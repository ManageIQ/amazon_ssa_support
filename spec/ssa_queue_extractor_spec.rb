require 'aws-sdk'

require_relative 'spec_helper'
require_relative 'aws_ssa_commons'

describe AmazonSsaSupport::SsaQueueExtractor do
  let(:args) { { :extractor_id => 'instance-id' } }

  subject { decribed_class.new(args) }

  context "parameters" do
    it "require a parameter" do
      expect { described_class.new }.to raise_error(ArgumentError)
    end

    it "require extractor_id" do
      args.delete(:extractor_id)
      expect { described_class.new(args) }.to raise_error(ArgumentError)
    end
  end
end
