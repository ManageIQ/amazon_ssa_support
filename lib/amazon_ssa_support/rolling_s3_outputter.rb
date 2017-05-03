require "log4r/outputter/fileoutputter"
require "log4r/staticlogger"

module Log4r

  class RollingS3Outputter < FileOutputter
    attr_reader :count, :maxsize

    def initialize(name, hash = {})
      @count           = 0
      @aws_args        = hash[:aws_args]
      @s3_log_prefix   = File.join(@aws_args[:log_prefix], @aws_args[:extractor_id])
      @evm_bucket      = AmazonSsaSupport::EvmBucket.get(@aws_args)

      maxsize = (hash[:maxsize] || hash['maxsize']).to_i
      if maxsize >= 2**62 || maxsize.zero?
        raise TypeError, "Argument 'maxsize' must be > 0 and < 2 ** 62", caller
      end
      @maxsize = maxsize
      @datasize = 0

      super(name, hash.merge(:create => true, :trunc => true))
    end

    def flush
      roll
    end

    private

    def write(data)
      # we have to keep track of the file size ourselves - File.size doesn't
      # seem to report the correct size when the size changes rapidly
      @datasize += data.size + 1 # the 1 is for newline
      super
      roll if @datasize > @maxsize
    end

    def s3_object_key
      log_id = Time.now.utc.strftime("%Y-%m-%dT%H:%M:%S")
      seq    = "0" * (6 - @count.to_s.length) + @count.to_s
      key    = File.join(@s3_log_prefix, "#{log_id}-#{seq}.log")
      @count += 1
      Logger.log_internal { "S3 obj key #{key} created" }
      key
    end

    def roll
      @out.close
      return if @datasize.zero?
      key = s3_object_key
      @evm_bucket.object(key).upload_file(@filename)
      # truncate the file
      @out = File.new(@filename, "w")
      @datasize = 0
    end
  end # class RollingS32Outputter

end # module Log4r
