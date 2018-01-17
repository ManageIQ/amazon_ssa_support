require 'MiqVm/MiqVm'

module AmazonSsaSupport
  class MiqEC2VmBase
    def initialize(ec2_obj, host_instance, ec2, ost)
      @ec2_obj       = ec2_obj
      @host_instance = host_instance
      @ec2           = ec2
      @ost           = ost
    end
  end
end
