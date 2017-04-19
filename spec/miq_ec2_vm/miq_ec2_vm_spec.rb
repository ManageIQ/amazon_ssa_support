require 'aws-sdk'

require_relative '../spec_helper'
require_relative '../aws_ssa_commons'

describe AmazonSsaSupport::MiqEC2Vm do
  before :each do
    @host         = mocked_ebs_instance('i-mocked-1')
    @ec2          = mocked_ec2
  end

  context "initialization" do
    let(:ec_image_id)    { 'ami-test-1' }
    let(:ec_instance_id) { 'i-test-1' }

    it "should return MiqEC2EbsImage" do
      expect(described_class.new(ec_image_id, @host, @ec2)).to be_a(AmazonSsaSupport::MiqEC2EbsImage)
      expect(described_class.new(ec_image_id, @host, @ec2)).not_to be_a(AmazonSsaSupport::MiqEC2EbsInstance)
    end

    it "should return MiqEC2EbsInstance" do
      expect(described_class.new(ec_instance_id, @host, @ec2)).to be_a(AmazonSsaSupport::MiqEC2EbsInstance)
      expect(described_class.new(ec_instance_id, @host, @ec2)).not_to be_a(AmazonSsaSupport::MiqEC2EbsImage)
    end
  end

  context "types checkings" do
    let(:ec_image_id)    { 'ami-test-1' }
    let(:ec_instance_id) { 'i-test-1' }
    let(:instance) { described_class.new(ec_instance_id, @host, @ec2) }
    let(:image) { described_class.new(ec_image_id, @host, @ec2) }

    it "instance.ebs_instance? should return true" do
      expect(instance.ebs_instance?).to be_truthy
    end

    it "instance.ebs_image? should return false" do
      expect(instance.ebs_image?).to be_falsey
    end

    it "image.ebs_instance? should return false" do
      expect(image.ebs_instance?).to be_falsey
    end

    it "image.ebs_image? should return true" do
      expect(image.ebs_image?).to be_truthy
    end
  end
end

