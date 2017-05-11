require_relative 'ssa_common'

module AmazonSsaSupport
  module SsaBucket
    def self.get(arg_hash)
      raise ArgumentError, "ssa_bucket must be specified." if arg_hash[:ssa_bucket].nil?

      ssa_bucket_name = arg_hash[:ssa_bucket]
      s3              = arg_hash[:s3] || Aws::S3::Resource.new(region: DEFAULT_REGION)

      if (ssa_bucket = s3.bucket(ssa_bucket_name)).exists?
        $log.debug("#{name}.#{__method__}: Found reply bucket #{ssa_bucket_name}")
      else
        $log.debug("#{name}.#{__method__}: Reply bucket #{ssa_bucket_name} does not exist, creating...")
        ssa_bucket.create
        $log.debug("#{name}.#{__method__}: Created reply bucket #{ssa_bucket_name}")
      end

      ssa_bucket
    end
  end
end
