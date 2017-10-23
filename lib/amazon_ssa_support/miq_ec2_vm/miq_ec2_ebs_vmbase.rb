require_relative 'miq_ec2_vmbase'
require_relative '../instance_metadata'

module AmazonSsaSupport
  class MiqEC2EbsVmBase < MiqEC2VmBase
    attr_reader :volumes

    def initialize(ec2_obj, host_instance, ec2)
      super
      @block_device_keys = ebs_ids
      @volumes           = []
      @miq_vm            = nil
      @cfg               = ''
    end

    def ebs_instance?
      @ec2_obj.respond_to?(:instance_id) ? true : false
    end

    def ebs_image?
      @ec2_obj.respond_to?(:instance_id) ? false : true
    end

    def extract(cat)
      miq_vm.extract(cat)
    end

    def unmount
      @miq_vm&.unmount
      unmap_volumes
    end

    def ebs_ids
      ids = []
      if ebs_instance?
        @ec2_obj.block_device_mappings.each do |dev|
          ids << dev.ebs.volume_id
        end
      else
        @ec2_obj.block_device_mappings.each do |dev|
          ids << dev.ebs.snapshot_id
        end
      end
      ids
    end

    def zone_name
      aim = InstanceMetadata.new
      aim.metadata('placement/availability-zone')
    end

    def miq_vm
      return @miq_vm unless @miq_vm.nil?

      raise "#{self.class.name}.miq_vm: could not map volumes" unless map_volumes
      `ls -l #{map_device_prefix}*`.each_line { |l| _log.debug("        #{l.chomp}") } if _log.debug?
      @cfg.each_line { |l| _log.debug("    #{l.chomp}") } if _log.debug?

      @miq_vm = MiqVm.new(@cfg)
    end

    def create_volume(snap_id)
      _log.info("    Creating volume based on #{snap_id}")
      snap = @ec2.snapshot(snap_id)
      if snap.nil?
        _log.warn("    Snapshot #{snap_id} does not exist (nil)")
        return nil
      end
      volume = @ec2.create_volume(snapshot_id: snap_id, availability_zone: zone_name)
      sleep 2
      @ec2.client.wait_until(:volume_available, volume_ids: [volume.id])

      volume.create_tags(tags: [{ key: 'Name', value: 'SSA extract volume'},
                                { key: 'Description', value: "SSA extract volume for image: #{@ec2_obj.id}"}])

      _log.info("    Volume #{volume.id} of snapshot #{snap_id} is created!")
      @volumes << volume

      volume
    end

    def map_volumes
      diskid = 'scsi0:0'

      @block_device_keys.each do |k|
        vol = create_volume(k)
        return false if vol.nil?

        # In Docker, mapdev is like /host_dev/xvdf; 
        mapdev = get_first_free_device(map_device_prefix)
        _log.info("    Attaching volume #{vol.id} to #{mapdev.gsub("host_dev", "dev")}")
        # Always attach to /dev block device, no matter inside docker or not
        vol.attach_to_instance(instance_id: @host_instance.id, device: mapdev.gsub("host_dev", "dev"))
        sleep 5
        @ec2.client.wait_until(:volume_in_use, volume_ids: [vol.id])
        _log.info("    Volume #{vol.id} is attached!")

        @cfg += "#{diskid}.present = \"TRUE\"\n"
        @cfg += "#{diskid}.filename = \"#{mapdev}\"\n"
        diskid.succ!
      end
      true
    end

    def unmap_volumes
      while (vol = @volumes.shift)
        attachment = vol.detach_from_instance(instance_id: @host_instance.id, force: true)

        _log.info("#{vol.id} is #{attachment.state}")
        @ec2.client.wait_until(:volume_available, volume_ids: [vol.id])
        vol.delete
        @ec2.client.wait_until(:volume_deleted, volume_ids: [vol.id])
        _log.info("Volume #{vol.id} is deleted!")
      end
    end

    def map_device_prefix
      File.exist?('/host_dev/') ? '/host_dev/xvd' : '/dev/xvd'
    end

    def get_first_free_device(device_prefix = '/dev/xvd')
      all_devices = []

      # Aws EC2 starts from /dev/xvdf
      ('f'..'z').each do |char|
        all_devices << "#{device_prefix}#{char}"
      end

      used_devices = `ls #{device_prefix}*`.split("\n")
      _log.debug("Mounted devices: #{used_devices}") if used_devices.any?

      available_devices = all_devices - used_devices
      raise "All devices are occupied!" if available_devices.empty?

      available_devices[0]
    end
  end
end
