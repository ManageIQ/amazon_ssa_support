require 'aws-sdk'

require_relative '../spec_helper'
require_relative '../aws_ssa_commons'

::Module.include(LogDecorator::Logging::ClassMethods)
include LogDecorator::Logging

describe AmazonSsaSupport::MiqEC2EbsInstance do
  before :each do
    @eb2_obj = mocked_ebs_instance('i-mocked-1')
    @host    = mocked_ebs_instance('i-mocked-2')
    @ec2     = mocked_ec2
  end

  subject { described_class.new(@eb2_obj, @host, @ec2) }

  context "Inheritance" do
    it "is subclass of Amazon::MiqEC2VmBase" do
      expect(AmazonSsaSupport::MiqEC2EbsInstance.ancestors).to include(AmazonSsaSupport::MiqEC2VmBase)
    end

    it "is subclass of Amazon::MiqEC2EbsVmBase" do
      expect(AmazonSsaSupport::MiqEC2EbsInstance.ancestors).to include(AmazonSsaSupport::MiqEC2EbsVmBase)
    end
  end

  context "Instance methods" do
    it "defines create_volume method" do
      expect(subject).to respond_to(:create_volume)
    end

    it "defines a unmap_volumes method" do
      expect(subject).to respond_to(:unmap_volumes)
    end
  end

  context ".ebs_instance?" do
    it "should return true" do
      expect(subject.ebs_instance?).to be_truthy
    end
  end

  context ".ebs_image?" do
    it "should return false" do
      expect(subject.ebs_image?).to be_falsey
    end
  end

  context "block_device_keys" do
    it "return ids" do
      expect(subject.ebs_ids).to eq(%w(vol_1 vol_2))
    end
  end

  context "zone_name" do
    it "defines a zone_name method" do
      expect(subject).to respond_to(:zone_name)
    end
  end

  context "miq_vm" do
    it "defines a miqVm method" do
      expect(subject).to respond_to(:miq_vm)
    end
  end

  context ".create_volume" do
    it "create a volume" do
      allow(subject).to receive(:zone_name).and_return('us-west-2')
      expect(subject.create_volume("snap-mocked-1").id).to eq(mocked_volume("vol-mocked-1").id)
      expect(subject.volumes.size).to eq(1)
      expect(subject.snapshots.size).to eq(1)
    end
  end

  context ".create_snapshot" do
    it "create a snapshot" do
      expect(subject.create_snapshot("vol-mocked-1").id).to eq(mocked_snapshot("snap-mocked-1").id)
      expect(subject.snapshots.size).to eq(1)
    end
  end

  context ".unmap_volume" do
    it "unmap a volume" do
      allow(subject).to receive(:zone_name).and_return('us-west-2')
      expect(subject.create_volume("snap-mocked-1").id).to eq(mocked_volume("vol-mocked-1").id)
      expect(subject.volumes.size).to eq(1)
      expect(subject.snapshots.size).to eq(1)

      subject.unmap_volumes
      expect(subject.volumes).to be_empty
      expect(subject.snapshots).to be_empty
    end
  end
end
