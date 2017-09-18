require 'httpclient'
require 'log_decorator'

module AmazonSsaSupport
  class InstanceMetadata
    include LogDecorator::Logging

    def initialize(version = 'latest')
      @base_url     = 'http://169.254.169.254/'
      @version      = version
      @url          = "#{@base_url}#{@version}/"
      @metadata_url = "#{@url}meta-data/"
      @http_client  = HTTPClient.new
    end

    def version=(val)
      @version      = val
      @url          = "#{@base_url}#{@version}/"
      @metadata_url = "#{@url}meta-data/"
      val
    end

    def versions
      do_get(@base_url, "versions").split("\n")
    end

    def metadata(path)
      rv = do_get(@metadata_url + path, "metadata")
      data = rv.split("\n")
      _log.warn("Metadata #{path} contains multiple attributes: #{data}, return the first one.") if data.size > 1
      data[0]
    end

    def userdata
      do_get(@url + "user-data", "user_data")
    end

    private

    def do_get(url, method)
      rv = @http_client.get(url)
      raise "#{self.class.name}.#{method}: #{url} #{rv.reason} (#{rv.status})" if rv.status != 200
      rv.content
    end
  end
end
