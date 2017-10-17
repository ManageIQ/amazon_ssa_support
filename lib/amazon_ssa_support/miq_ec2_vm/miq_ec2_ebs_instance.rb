require_relative 'miq_ec2_ebs_vmbase'

module AmazonSsaSupport
  class MiqEC2EbsInstance < MiqEC2EbsVmBase
    include LogDecorator::Logging
    attr_reader :snapshots

    def initialize(ec2_obj, host_instance, ec2)
      super
      @snapshots = []
    end

    def unmap_volumes
      super
      while (snap = @snapshots.shift)
        snap.delete
      end
    end

    def create_volume(id)
      _log.debug("    Creating snapshot of instance volume #{id}")
      snap = @ec2.create_snapshot(volume_id: id, description: "MIQ extract snapshot for instance: #{@ec2_obj.id}")
      snap.wait_until_completed
      snap.create_tags(tags: [{key: 'Name', value: 'MIQ extract snapshot'}])
      _log.debug("    Creating snapshot of instance volume #{id} DONE snap_id = #{snap.id}")
      @snapshots << snap
      super(snap.id)
    end
  end
end
