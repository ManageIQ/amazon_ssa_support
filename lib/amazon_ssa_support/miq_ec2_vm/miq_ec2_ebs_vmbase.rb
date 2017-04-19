require_relative 'miq_ec2_vmbase'
require_relative '../instance_metadata'

module AmazonSsaSupport
  class MiqEC2EbsVmBase < MiqEC2VmBase
    attr_reader :volumes

    def initialize(ec2_obj, host_instance, ec2, iargs)
      super
      @block_device_keys = ebs_ids
      @volumes = []
      @miqVm = nil
    end
  
    def ebs_instance?
      @ec2_obj.respond_to?(:instance_id) ? true : false
    end
    
    def ebs_image?
      @ec2_obj.respond_to?(:instance_id) ? false : true
    end
    
    def extract(cat)
      miqVm.extract(cat)
    end
    
    def unmount
      @miqVm.unmount unless @miqVm.nil?
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
    
    def miqVm
      return @miqVm unless @miqVm.nil?
      
      raise "#{self.class.name}.miqVm: could not map volumes" unless map_volumes
      `ls -l /dev/xvd*`.each_line { |l| $log.debug "        #{l.chomp}" } if $log.debug?
      cfg = getCfg
      cfg.each_line { |l| $log.debug "    #{l.chomp}" } if $log.debug?
      
      return(@miqVm = MiqVm.new(cfg))
    end
    
    def getCfg
      diskid = 'scsi0:0'
      mapdev = '/dev/xvdf'
      hardware = ''
      @block_device_keys.each do |k|
        hardware += "#{diskid}.present = \"TRUE\"\n"
        hardware += "#{diskid}.filename = \"#{mapdev}\"\n"
        diskid.succ!
        mapdev.succ!
      end
      return hardware
    end
  
    def create_snapshot(vol_id)
      return vol_id if ebs_image?
  
      $log.debug "    Creating snapshot of instance volume #{vol_id}"
      snap = @ec2.create_snapshot(volume_id: vol_id, description: "EVM extract snapshot for instance: #{@ec2_obj.id}")
      snap.wait_until_completed
      snap.create_tags(tags: [{key: 'Name', value: 'EVM extract snapshot'}])
      $log.debug "    Creating snapshot of instance volume #{vol_id} DONE snap_id = #{snap.id}"
      @snapshots << snap
      snap
    end
    
    def create_volume(snap_id)
      $log.debug "    Creating volume based on #{snap_id}"
      snap = @ec2.snapshot(snap_id)
      if snap.nil?
        $log.info "    Snapshot #{snap_id} does not exist (nil)"
        return nil
      end
      volume = @ec2.create_volume(snapshot_id: snap_id, availability_zone: zone_name)
      sleep 2
      @ec2.client.wait_until(:volume_available, {volume_ids: [volume.id]})
                      
      volume.create_tags(tags: [ { key: 'Name', value: 'EVM extract volume'},
               { key: 'Description', value: "EVM extract volume for image: #{@ec2_obj.id}"}])
      
      $log.debug "    Creating volume based on #{snap_id} DONE"
      @volumes << volume
      $log.debug "    Volume size: #{@volumes.size}"
      
      return volume
    end
    
    def map_volumes(mapdev='/dev/xvdf')
      @block_device_keys.each do |k|
        vol = create_volume(k)
        return false if vol.nil?
        $log.debug "    Attaching volume #{vol.id} to #{mapdev}"
        attachment = vol.attach_to_instance(instance_id: @host_instance.id, device: mapdev)
        sleep 5
        @ec2.client.wait_until(:volume_in_use, {volume_ids: [vol.id]})
        $log.debug "    Volume #{vol.id} is attached!"
        mapdev.succ!
      end
      return true
    end
  
    def unmap_volumes
      while (vol = @volumes.shift)
        attachment = vol.detach_from_instance(instance_id: @host_instance.id, force: true)
        
        $log.debug "#{self.class.name}.#{__method__}: #{vol.id} is #{attachment.state}"
        @ec2.client.wait_until(:volume_available, {volume_ids: [vol.id]})
        vol.delete
        @ec2.client.wait_until(:volume_deleted, {volume_ids: [vol.id]})
        $log.debug "#{self.class.name}.#{__method__}: volume #{vol.inspect} is deleted!"
      end
  
      while (snap = @snapshots.shift)
        snap.delete
      end
    end
    
  end
end
