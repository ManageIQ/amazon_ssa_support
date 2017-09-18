# Constants and methods
module AmazonSsaSupport
  DEFAULT_HEARTBEAT_PREFIX   = 'extract/heartbeart/'.freeze
  DEFAULT_HEARTBEAT_INTERVAL = 120

  DEFAULT_REQUEST_QUEUE      = 'ssa_extract_request'.freeze
  DEFAULT_REPLY_QUEUE        = 'ssa_extract_reply'.freeze

  DEFAULT_REPLY_PREFIX       = 'extract/queue-reply/'.freeze
  DEFAULT_LOG_PREFIX         = 'extract/logs/'.freeze

  DEFAULT_LOG_LEVEL          = 'INFO'.freeze
  DEFAULT_BUCKET_PREFIX      = 'miq-ssa'.freeze
end
