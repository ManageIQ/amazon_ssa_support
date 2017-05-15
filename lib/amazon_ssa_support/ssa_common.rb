# Constants and methods
module AmazonSsaSupport
  DEFAULT_REGION             = 'us-west-2'.freeze
  DEFAULT_HEARTBEAT_PREFIX   = 'extract/heartbeart/'.freeze
  DEFAULT_HEARTBEAT_INTERVAL = 120
  DEFAULT_REPLY_PREFIX       = 'extract/queue-reply/'.freeze

  DEFAULT_REQUEST_QUEUE      = 'ssa_extract_request'.freeze
  DEFAULT_REPLY_QUEUE        = 'ssa_extract_reply'.freeze
end
