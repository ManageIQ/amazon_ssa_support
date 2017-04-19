require 'yaml'
require 'aws-sdk'

require_relative 'miq_ec2_vm/miq_ec2_vm'
require_relative 'evm_queue'

module AmazonSsaSupport
  class EvmQueueExtractor
    
    CATEGORIES  = ["accounts", "services", "software", "system"]
    attr_reader :myInstance, :eeq
    
    def initialize(aws_args)
      raise ArgumentError, "extractor_id must be specified." if aws_args[:extractor_id].nil?
      @aws_args = aws_args
      @extractor_id  = @aws_args[:extractor_id]
      @reg           = @aws_args[:region] || DEFAULT_REGION
      
      @ec2 = @aws_args[:ec2] || Aws::EC2::Resource.new(region: @reg)
      @myInstance  = @ec2.instance(@extractor_id)
      @eeq = EvmQueue.new(@aws_args)
      
      @exit_code = nil
    end
    
    def extract_loop
      $log.info "#{self.class.name}.#{__method__} entered"
      @eeq.get_request_loop do |req|
        $log.info "#{self.class.name}.#{__method__} got message #{req[:sqs_msg].message_id}"
        process_request(req)
        return @exit_code if @exit_code
        $log.debug { "#{self.class.name}.#{__method__} waiting for next message" }
      end
    end
    
    def process_request(req)
      req_type = req[:request_type]
      $log.info "#{self.class.name}.#{__method__}: processing request - #{req_type}"
      case req_type
      when :extract
        do_extract(req)
      when :exit, :reboot, :shutdown
        do_ers(req)
      else
        $log.error "#{self.class.name}.#{__method__}: Unrecognized request #{req_type}"
        @eeq.delete_request(req)
      end
      $log.info "#{self.class.name}.#{__method__}: completed processing request - #{req_type}"
    end
    
    def do_extract(req)
      @eeq.delete_request(req)
      extract_reply = @eeq.new_reply(req)
      begin
        ec2Vm = MiqEC2Vm.new(req[:ec2_id], @myInstance, @ec2, @aws_args)
        puts "MiqEC2Vm: #{ec2Vm.inspect} " 
        categories = req[:categories] || CATEGORIES
        $log.info "categories: #{categories.inspect}"
        $log.info { "MiqEC2Vm: #{ec2Vm.class.name} - categories = [ #{categories.join(', ')} ]" }
        puts "MiqEC2Vm: #{ec2Vm.class.name} - categories = [ #{categories.join(', ')} ]" 
        categories.each do |cat|
          xml = ec2Vm.extract(cat)
          puts "#{cat}-xml: #{xml.inspect}"
          extract_reply.add_category(cat, xml)
        end
      rescue => err
        extract_reply.error = err.to_s
        $log.error err.to_s
        $log.error err.backtrace.join("\n")
      ensure
        extract_reply.reply
        ec2Vm.unmount
      end
    end
    
    def do_ers(req)
      if req[:extractor_id] != @extractor_id
        if req_target_exists?(req)
          $log.debug { "#{self.class.name}.#{__method__}: re-queueing request: #{req[:sqs_msg].id}" }
          @eeq.requeue_request(req)
        else
          $log.debug { "#{self.class.name}.#{__method__}: deleting request: #{req[:sqs_msg].id}" }
          @eeq.delete_request(req)
        end
        return
      end
      @exit_code = req[:request_type]
      @eeq.delete_request(req)
      @eeq.send_ers_reply(req)
    end
    
    def req_target_exists?(req)
      @ec2.instances[req[:extractor_id]].exists?
    end
    private :req_target_exists?
    
  end 
end
