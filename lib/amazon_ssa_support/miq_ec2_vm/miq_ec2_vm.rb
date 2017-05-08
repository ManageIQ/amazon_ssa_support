require_relative 'miq_ec2_ebs_image'
require_relative 'miq_ec2_ebs_instance'

module AmazonSsaSupport
  class MiqEC2Vm
    def self.new(ec2_id, host_instance, ec2)
      if ec2_id[0, 4] == "ami-"
        ec2_obj = ec2.image(ec2_id)
        raise "MiqEC2Vm.new: EC2 Image #{ec2_id} not found" unless ec2_obj
        raise "MiqEC2Vm.new: Image of instance store isn't supported!" unless ec2_obj.root_device_type == "ebs"
        MiqEC2EbsImage.new(ec2_obj, host_instance, ec2)
      elsif ec2_id[0, 2] == "i-"
        ec2_obj = ec2.instance(ec2_id)
        raise "MiqEC2Vm.new: EC2 Instance #{ec2_id} not found" unless ec2_obj
        raise "MiqEC2Vm.new: Instance of instance store isn't supported!" unless ec2_obj.root_device_type == "ebs"
        MiqEC2EbsInstance.new(ec2_obj, host_instance, ec2)
      else
        raise "MiqEC2Vm.new: unrecognized ec2 ID #{ec2_id}"
      end
    end
  end
end
