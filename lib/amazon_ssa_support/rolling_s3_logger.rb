require "logger"
require "time"

module AmazonSsaSupport
  class RollingS3Logger < Logger
    def initialize(logdev, shift_age = 1, shift_size = 1_048_576, log_to_stderr = nil)
      if log_to_stderr
        STDERR.sync = true
        @stderr_logger = Logger.new(STDERR)
      end

      super(logdev, shift_age, shift_size)

      @logdev.singleton_class.prepend(LogDeviceMixin)
    end

    def add(*args)
      @stderr_logger&.add(*args)
      super
    end

    def level=(value)
      @stderr_logger&.level = value
      super
    end

    def progname=(value)
      @stderr_logger&.progname = value
      super
    end

    def formatter=(value)
      @stderr_logger&.formatter = value
      super
    end

    def aws_args=(args)
      @logdev.aws_args = args
    end

    def roll
      @logdev.roll
    end

    module LogDeviceMixin
      def aws_args=(args)
        if !args.kind_of?(Hash) || !args.include?(:log_prefix) || !args.include?(:extractor_id)
          raise ArgumentError, "aws_args must be a Hash including :log_prefix and :extractor_id keys"
        end

        @s3_log_prefix = File.join(args[:log_prefix], args[:extractor_id])
        @ssa_bucket    = AmazonSsaSupport::SsaBucket.get(args)
        @count = 0
      end

      def roll
        return unless @ssa_bucket && @filename

        log_id = Time.now.utc.iso8601.chop
        seq    = @count.to_s.rjust(6, "0")
        @count += 1
        s3_object_key = File.join(@s3_log_prefix, "#{log_id}-#{seq}.log")
        begin
          @ssa_bucket.object(s3_object_key).upload_file(@filename)
        rescue => err
          STDERR.puts("Unable to roll log to S3: #{err.class} - #{err}")
          nil
        end
      end

      private

      def shift_log_age
        roll
        super
      end

      def shift_log_period(period_end)
        roll
        super
      end
    end
  end
end
