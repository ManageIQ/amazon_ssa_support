require_relative 'evm_common'

module AmazonSsaSupport
  module EvmBucket
    
    def self.get(arg_hash)
      raise ArgumentError, "evm_bucket must be specified." if arg_hash[:evm_bucket].nil?

      evm_bucket_name = arg_hash[:evm_bucket]
      reply_prefix    = arg_hash[:reply_prefix] || AmazonSsaSupport::DEFAULT_REPLY_PREFIX
      s3              = arg_hash[:s3] || Aws::S3::Resource.new(region: DEFAULT_REGION)
      
      unless (evm_bucket = s3.bucket(evm_bucket_name)).exists?
        $log.debug("#{self.name}.#{__method__}: Reply bucket #{evm_bucket_name} does not exist, creating...")
        evm_bucket.create
        $log.debug("#{self.name}.#{__method__}: Created reply bucket #{evm_bucket_name}")
      else
        $log.debug("#{self.name}.#{__method__}: Found reply bucket #{evm_bucket_name}")
      end
      
      evm_bucket
    end
    
  end
end
