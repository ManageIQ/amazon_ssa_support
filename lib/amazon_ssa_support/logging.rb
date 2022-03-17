module AmazonSsaSupport
  class << self
    attr_writer :logger
  end

  def self.logger
    @logger ||= $log || begin
      require 'logger'
      Logger.new($stdout)
    end
  end

  module Logging
    def self.included(base)
      base.extend(self)
    end

    def _log
      AmazonSsaSupport.logger
    end
  end
end
