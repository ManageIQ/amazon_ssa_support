require 'yaml'
require 'aws-sdk'

require_relative 'miq_ec2_vm/miq_ec2_vm'
require_relative 'ssa_queue'

module AmazonSsaSupport
  class SsaQueueExtractor
    include LogDecorator::Logging

    CATEGORIES = %w(accounts services software system).freeze
    attr_reader :my_instance, :ssaq

    def initialize(aws_args)
      raise ArgumentError, "Region must be specified." if aws_args[:region].nil?
      @aws_args     = aws_args
      @extractor_id = @aws_args[:extractor_id]
      @region       = @aws_args[:region]

      @ec2          = @aws_args[:ec2] || Aws::EC2::Resource.new(:region => @region)
      @my_instance  = @ec2.instance(@extractor_id)
      @ssaq         = SsaQueue.new(@aws_args)
      @exit_code    = nil
    end

    def extract_loop(timeout)
      start = Time.now.to_i
      loop do
        begin
          @ssaq.request_loop do |req|
            _log.debug("Got message #{req[:sqs_msg].message_id}")
            process_request(req)
            start = Time.now.to_i # reset time counter after message is processed
            return @exit_code if @exit_code
            _log.info("Waiting for next message")
          end
        end
        break if (Time.now.to_i - start) >= timeout
      end
      _log.info("No messages received in #{timeout} seconds, agent shuts down!!!")
      @exit_code = :shutdown
    end

    def process_request(req)
      req_type = req[:request_type]
      _log.debug("Processing request - #{req_type}")
      case req_type
      when :extract
        do_extract(req)
      when :exit, :reboot, :shutdown
        do_ers(req)
      else
        _log.error("Unrecognized request #{req_type}")
        @ssaq.delete_request(req)
      end
      _log.debug("Completed processing request - #{req_type}")
    rescue => err
      _log.error(err.to_s)
      _log.error(err.backtrace.join("\n"))
    end

    def do_extract(req)
      @ssaq.delete_request(req)
      extract_reply = @ssaq.new_reply(req)
      begin
        ec2_vm = MiqEC2Vm.new(req[:ec2_id], @my_instance, @ec2)
        categories = req[:categories] || CATEGORIES
        _log.info("categories: #{categories.inspect}")
        categories.each do |cat|
          begin
            xml = ec2_vm.extract(cat)
            extract_reply.add_category(cat, xml)
          # continue to extract other category even when one failed
          rescue => err
            _log.error(err.to_s)
            _log.error(err.backtrace.join("\n"))
          end
        end
      rescue => err
        extract_reply.error = err.to_s
        _log.error(err.to_s)
        _log.error(err.backtrace.join("\n"))
      ensure
        extract_reply.reply
        ec2_vm&.unmount
      end
    end

    def do_ers(req)
      if req[:extractor_id] != @extractor_id
        if req_target_exists?(req)
          _log.debug("Re-queueing request: #{req[:sqs_msg].id}")
          @ssaq.requeue_request(req)
        else
          _log.debug("Deleting request: #{req[:sqs_msg].id}")
          @ssaq.delete_request(req)
        end
        return
      end
      @exit_code = req[:request_type]
      @ssaq.delete_request(req)
      @ssaq.send_ers_reply(req)
    end

    def req_target_exists?(req)
      @ec2.instances[req[:extractor_id]].exists?
    end
    private :req_target_exists?
  end
end
