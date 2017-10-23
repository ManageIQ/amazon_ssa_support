require_relative 'miq_ec2_ebs_vmbase'

module AmazonSsaSupport
  class MiqEC2EbsInstance < MiqEC2EbsVmBase
    attr_reader :snapshots

    def initialize(ec2_obj, host_instance, ec2)
      super
      @snapshots = []
    end

    def unmap_volumes
      super
      while (snap = @snapshots.shift)
        snap.delete
        _log.info("Snapshot #{snap.id} is deleted!")
      end
    end

    def create_snapshot(vol_id)
      _log.info("    Creating snapshot of instance volume #{vol_id}")
      snap = @ec2.create_snapshot(volume_id: vol_id, description: "SSA extract snapshot for instance: #{@ec2_obj.id}")
      snap.wait_until_completed
      snap.create_tags(tags: [{key: 'Name', value: 'SSA extract snapshot'}])
      _log.info("    Snapshot #{snap.id} of instance volume #{vol_id} is created!")
      @snapshots << snap
      snap
    end

    def create_volume(id)
      snap = create_snapshot(id)
      super(snap.id)
    end
  end
end
