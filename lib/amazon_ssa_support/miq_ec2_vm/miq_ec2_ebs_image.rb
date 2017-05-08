require_relative 'miq_ec2_ebs_vmbase'

module AmazonSsaSupport
  class MiqEC2EbsImage < MiqEC2EbsVmBase
    def initialize(ec2_obj, host_instance, ec2)
      super
    end
  end
end
