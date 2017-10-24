require 'yaml'
require 'aws-sdk'

require_relative 'ssa_common'
require_relative 'ssa_bucket'

module AmazonSsaSupport
  class SsaQueue
    attr_reader :ssa_bucket_name, :ssa_region, :request_queue_name, :reply_queue_name, :reply_bucket_name, :extractor_id
    attr_reader :request_queue, :reply_queue, :reply_bucket, :reply_prefix, :sqs

    def initialize(args)
      @extractor_id       = args[:extractor_id]
      @ssa_bucket_name    = args[:ssa_bucket]
      @ssa_region         = args[:region]
      @request_queue_name = args[:request_queue] || DEFAULT_REQUEST_QUEUE
      @reply_queue_name   = args[:reply_queue] || DEFAULT_REPLY_QUEUE
      @reply_prefix       = args[:reply_prefix] || DEFAULT_REPLY_PREFIX

      unless ssa_bucket_name && ssa_region
        raise ArgumentError, "bucket & region must be specified."
      end

      _log.debug("request_queue_name = #{@request_queue_name}")
      _log.debug("reply_queue_name   = #{@reply_queue_name}")
      _log.debug("ssa_bucket_name    = #{@ssa_bucket_name}")
      _log.debug("extractor_id       = #{@extractor_id}")

      @sqs = args[:sqs] || Aws::SQS::Resource.new(region: @ssa_region)

      @request_queue = find_or_create_queue(@sqs, @request_queue_name)
      @reply_queue   = find_or_create_queue(@sqs, @reply_queue_name)

      @reply_bucket = SsaBucket.get(args)
    end

    def find_or_create_queue(sqs, name)
      sqs.get_queue_by_name(queue_name: name)
    rescue Aws::SQS::Errors::NonExistentQueue
      _log.debug("Queue #{name} does not exist, creating...")
      sqs.create_queue(queue_name: name)
    rescue Aws::SQS::Errors::ServiceError => exception
      raise exception.message
    end

    ##################
    # Request methods
    ##################

    #
    # Send a request to extract data from the image/instance
    # whose ID is ec2_id.
    #
    def send_extract_request(ec2_id, job_id = nil, categories = nil)
      request = {}
      request[:request_type] = :extract
      request[:ec2_id]       = ec2_id
      request[:job_id]       = job_id
      request[:categories]   = categories
      @request_queue.send_message(message_body: YAML.dump(request, safe: true))
    end

    #
    # Send a request instructing the extractor, whose ID is extractor_id, to exit.
    #
    def send_exit_request(extractor_id)
      send_ers_request(:exit, extractor_id)
    end

    #
    # Send a request instructing the extractor, whose ID is extractor_id, to reboot.
    #
    def send_reboot_request(extractor_id)
      send_ers_request(:reboot, extractor_id)
    end

    #
    # Send a request instructing the extractor, whose ID is extractor_id, to shutdown.
    #
    def send_shutdown_request(extractor_id)
      send_ers_request(:shutdown, extractor_id)
    end

    def send_ers_request(request_type, extractor_id)
      request = {}
      request[:request_type] = request_type
      request[:extractor_id] = extractor_id
      @request_queue.send_message(message_body: YAML.dump(request, safe: true))
    end
    private :send_ers_request

    #
    # Extractor loop, reading requests from the queue.
    #
    def request_loop
      @request_queue.receive_messages.each do |msg|
        yield(get_request(msg))
      end
    end

    def get_request(msg)
      req = YAML.load(msg.body, safe: true)
      _log.debug("req: #{req.inspect}")
      req[:sqs_msg] = msg
      req
    end
    private :get_request

    #
    # Used by extractor to re-queue requests that it can't service.
    #
    def requeue_request(req)
      msg = req[:sqs_msg]
      body = YAML.load(msg.body, safe: true)
      if body[:original_req_id]
        @request_queue.send_message(message_body: msg.body, delay_seconds: 10)
      else
        body[:original_req_id] = msg.message_id
        @request_queue.send_message(message_body: YAML.dump(body, safe: true), delay_seconds: 10)
      end
      msg.delete
    end

    #
    # Delete the request from the queue.
    #
    def delete_request(req)
      req[:sqs_msg].delete
    end

    #################
    # Reply methods
    #################

    #
    # Loop, reading extraction replies from extractors.
    #
    def reply_loop
      @reply_queue.receive_messages.each do |msg|
        next if (reply = get_reply(msg)).nil?
        yield(reply)
      end
    end

    def get_reply(msg)
      body = YAML.load(msg.body, safe: true)

      case body[:reply_type]
      when :extract
        req_id = body[:request_id]
        s3_obj_name = @reply_prefix + req_id
        s3_obj = @reply_bucket.object(s3_obj_name)
        unless s3_obj.exists?
          msg.delete
          $log.error("Reply object #{s3_obj_name} does not exist")
          return nil
        end
        reply_data = YAML.load(s3_obj.get.body.read, safe: true)
        reply_data[:request_id] = req_id
        reply_data[:sqs_msg] = msg
        s3_obj.delete
        return reply_data
      when :exit, :reboot, :shutdown
        body[:sqs_msg] = msg
        return body
      else
        _log.warn("Unrecognized reply type #{body[:reply_type]}")
        return nil
      end
    end
    private :get_reply

    #
    # ers_reply = {
    #  :reply_type    => :exit || :reboot || :shutdown
    #  :extractor_id  => <The ID of the target of the request>
    #  :request_id    => <The ID of the original request - not re-queued request>
    # }
    #
    def send_ers_reply(req)
      ers_reply = {}
      ers_reply[:reply_type]   = req[:request_type]
      ers_reply[:extractor_id] = @extractor_id
      ers_reply[:request_id]   = req[:original_req_id]

      msg = @reply_queue.send_message(message_body: YAML.dump(ers_reply, safe: true))
      _log.debug("Sent reply (#{ers_reply[:reply_type]}) #{@reply_queue_name}:#{msg.message_id} to #{@request_queue_name}:#{ers_reply[:request_id]}")
    end

    #
    # Instantiate a new extract reply object for the extractor.
    #
    def new_reply(req)
      SsaReply.new(req, self)
    end

    #
    # extract_reply = {
    #  :reply_type    => :extract
    #   :ec2_id      => <The ec2 id of the image/instance>,
    #  :job_id      => <The id of the ssa job requesting the extraction>,
    #  :extractor_id  => <The id of the ssa extractor instance performing the extract>
    #   :start_time    => <The time the extraction started>,
    #   :end_time    => <The time the extraction completed>,
    #   :error      => <Error text and stack trace - if there was an error>,
    #   :categories  => {
    #     :accounts  => <XML text for accounts>,
    #     :services  => <XML text for services>,
    #     :software  => <XML text for software>,
    #     :system    => <XML text for system>
    #   }
    # }
    #
    class SsaReply
      def initialize(req, ssaq)
        @ssaq = ssaq

        @req_id                       = req[:sqs_msg].message_id
        @req_obj_name                 = @ssaq.reply_prefix + @req_id
        @extract_reply                = {}
        @extract_reply[:reply_type]   = req[:request_type]
        @extract_reply[:categories]   = {}
        @extract_reply[:ec2_id]       = req[:ec2_id]
        @extract_reply[:job_id]       = req[:job_id]
        @extract_reply[:extractor_id] = @ssaq.extractor_id
        @extract_reply[:start_time]   = Time.now.utc.to_s # XXX keep this a Time object?
      end

      def error=(val)
        @extract_reply[:error] = val
      end

      def add_category(cat, xml)
        @extract_reply[:categories][cat.to_sym] = xml.to_xml.to_s
      end

      def reply
        @extract_reply[:end_time] = Time.now.utc.to_s # XXX keep this a Time object?
        @ssaq.reply_bucket.object(@req_obj_name).put(body: YAML.dump(@extract_reply, safe: true), content_type: "text/plain")
        reply_msg = {}
        reply_msg[:request_id] = @req_id
        reply_msg[:reply_type] = @extract_reply[:reply_type]
        msg = @ssaq.reply_queue.send_message(message_body: YAML.dump(reply_msg, safe: true))
        _log.debug("Sent reply (#{@extract_reply[:reply_type]}) #{@ssaq.reply_queue_name}:#{msg.message_id} to #{@ssaq.request_queue_name}:#{@req_id}")
      end
    end
  end
end
