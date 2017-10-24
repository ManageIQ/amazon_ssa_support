require 'yaml'
require 'aws-sdk'

require 'log_decorator'
require_relative 'ssa_common'
require_relative 'ssa_bucket'

module AmazonSsaSupport
  class SsaHeartbeat
    attr_reader :extractor_id, :heartbeat_prefix
    attr_reader :heartbeat_thread, :heartbeat_interval

    def initialize(args)
      raise ArgumentError, "Region must be specified" if args[:region].nil?

      @extractor_id       = args[:extractor_id]
      @region             = args[:region]
      @s3                 = args[:s3] || Aws::S3::Resource.new(:region => @region)
      @ssa_bucket         = SsaBucket.get(args)
      @heartbeat_prefix   = args[:heartbeat_prefix]
      @heartbeat_interval = args[:heartbeat_interval]
      @heartbeat_obj_key  = File.join(@heartbeat_prefix, @extractor_id) if @extractor_id
      @heartbeat_thread   = nil
      @do_heartbeat       = true

      _log.debug("extractor_id       = #{@extractor_id}")
      _log.debug("ssa_bucket         = #{@ssa_bucket.name}")
      _log.debug("heartbeat_prefix   = #{@heartbeat_prefix}")
      _log.debug("heartbeat_interval = #{@heartbeat_interval}")
    end

    def start_heartbeat_loop
      return unless @heartbeat_thread.nil?
      _log.debug("Starting heartbeat loop (#{object_id})")
      @heartbeat_thread = Thread.new do
        while @do_heartbeat
          begin
            heartbeat
          rescue StandardError => err
            _log.warn(err.to_s)
            _log.warn(err.backtrace.join("\n"))
          end
          sleep @heartbeat_interval
        end
        _log.debug("Exiting heartbeat loop")
        @heartbeat_thread = nil
      end
    end

    def stop_heartbeat_loop
      return if @heartbeat_thread.nil?
      @do_heartbeat = false
      while @heartbeat_thread && @heartbeat_thread.alive?
        @heartbeat_thread.run
      end
    end

    def heartbeat
      ts = Time.now.utc
      _log.debug("#{@extractor_id} --> #{ts}")
      _log.debug("obj_key: #{@heartbeat_obj_key}")
      @ssa_bucket.object(@heartbeat_obj_key).put(:body => YAML.dump(ts), :content_type => 'text/xml')
    end

    def get_heartbeat(extractor_id)
      heartbeat_obj_key = File.join(@heartbeat_prefix, extractor_id)
      hbobj = @ssa_bucket.object(heartbeat_obj_key)
      return nil unless hbobj.exists?
      hbobj.last_modified.utc
    end
  end
end
