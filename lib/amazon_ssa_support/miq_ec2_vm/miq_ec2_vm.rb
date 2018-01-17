require_relative 'miq_ec2_ebs_image'
require_relative 'miq_ec2_ebs_instance'

module AmazonSsaSupport
  class MiqEC2Vm
    def self.new(ec2_id, host_instance, ec2, ost = nil)
      ec2_obj = nil

      if ec2_id[0, 4] == "ami-"
        ec2_obj = ec2.image(ec2_id)
      elsif ec2_id[0, 2] == "i-"
        ec2_obj = ec2.instance(ec2_id)
      else
        raise "MiqEC2Vm.new: unrecognized ec2 ID #{ec2_id}"
      end

      raise "MiqEC2Vm.new: Instance store isn't supported!" unless ec2_obj&.root_device_type == "ebs"

      ec2_obj.respond_to?(:instance_id) ? MiqEC2EbsInstance.new(ec2_obj, host_instance, ec2, ost) : MiqEC2EbsImage.new(ec2_obj, host_instance, ec2, ost)
    end
  end
end
