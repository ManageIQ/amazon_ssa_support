require 'rubygems'
require 'bundler/setup'

require 'optparse'
require 'log4r'
require 'log4r/configurator'

require 'aws-sdk'
#
# We must do this before anything accesses log4r.
#
module Log4r
  Configurator.custom_levels(:DEBUG, :INFO, :WARN, :ERROR, :FATAL, :COPY)
end

class LogFormatter < Log4r::Formatter
  @@prog         = File.basename(__FILE__, ".*")
  @@extractor_id = ''
  def format(event)
    return event.data.chomp + "\n" if event.level == Log4r::COPY
    
    "#{Log4r::LNAMES[event.level]} [#{datetime}" +
    (@@extractor_id.nil? ? "" : " #{@@extractor_id}") +
    "] -- #{@@prog}: " +
    (event.data.kind_of?(String) ? event.data : event.data.inspect) + "\n"
  end
  
  def self.extractor_id=(val)
    @@extractor_id = val
  end

  private

  def datetime
    time = Time.now.utc
    time.strftime("%Y-%m-%dT%H:%M:%S.") << "%06d" % time.usec
  end
end

LOG_LEVELS = {
  'DEBUG'      => Log4r::DEBUG,
  'INFO'       => Log4r::INFO,
  'WARN'       => Log4r::WARN,
  'ERROR'      => Log4r::ERROR,
  'FATAL'      => Log4r::FATAL,
  'COPY'       => Log4r::COPY,
  Log4r::DEBUG => "DEBUG",
  Log4r::INFO  => "INFO",
  Log4r::WARN  => "WARN",
  Log4r::ERROR => "ERROR",
  Log4r::FATAL => "FATAL",
  Log4r::COPY  => "COPY"
}

require 'amazon_ssa_support'
require 'manageiq-gems-pending'

cmdName       = File.basename($0)
log_level_str = nil
max_log_size  = nil
log_to_stderr = false

#
# Process command line args.
#
OptionParser.new do |opts|
  opts.banner = "Usage: #{cmdName} [options]"

  opts.on('--log-to-stderr', "Log to stderr in addition to the log file")  do
    log_to_stderr = true
  end
  opts.on('-l', '--loglevel ARG', "The log level: DEBUG|INFO|WARN|ERROR|FATAL")  do |ll|
    raise OptionParser::ParseError.new("Unrecognized log level: #{ll}") if !(/DEBUG|INFO|WARN|ERROR|FATAL/i =~ ll)
    log_level_str = ll.upcase
  end
  opts.on('--max-log-size ARG', "Roll to S3 after log file exceeds this size")  do |mls|
    n = max_log_size.to_i
    raise OptionParser::ParseError.new("Max log size must be >= 256") if n < 256
    max_log_size = n
  end

  begin
    opts.parse!(ARGV)
  rescue OptionParser::ParseError => perror
    $stderr.puts cmdName + ": " + perror.to_s
    $stderr.puts
    $stderr.puts opts.to_s
    exit 1
  end
end

begin

  #
  # Get info and args associated with this extractor instance.
  #
  im                      = AmazonSsaSupport::InstanceMetadata.new
  extractor_id            = im.metadata('instance-id')
  aws_args                = YAML.load(File.open('default_ssa_config.yml'))
  aws_args[:extractor_id] = extractor_id
  reg                     = aws_args[:region]

  
  aws_args[:ec2] = Aws::EC2::Resource.new(region: reg)
  aws_args[:sqs] = Aws::SQS::Resource.new(region: reg)
  aws_args[:s3]  = Aws::S3::Resource.new(region: reg)
  
  #
  # Logging args.
  #
  aws_args[:log_level] = log_level_str unless log_level_str.nil? # command line override
  log_level            = LOG_LEVELS[aws_args[:log_level]]
  max_log_size       ||= aws_args[:max_log_size] || 1024 * 256
  logFile              = File.join('/opt/miq/log', 'extract.log')
  log_args = {
    :formatter => LogFormatter,
    :filename  => logFile,
    :maxsize   => max_log_size,
    :aws_args  => aws_args
  }
  
  #
  # Initialize logging.
  #
  LogFormatter.extractor_id = extractor_id
  $log = Log4r::Logger.new 'toplog'
  $log.level = log_level
  lfo = Log4r::RollingS3Outputter.new('log_s3', log_args)
  lfo.only_at(Log4r::DEBUG, Log4r::INFO, Log4r::WARN, Log4r::ERROR, Log4r::FATAL, Log4r::COPY)
  $log.add 'log_s3'
  at_exit { lfo.flush }

  if log_to_stderr
    eso = Log4r::StderrOutputter.new('err_console', :formatter=>LogFormatter)
    eso.only_at(Log4r::DEBUG, Log4r::INFO, Log4r::WARN, Log4r::ERROR, Log4r::FATAL, Log4r::COPY)
    $log.add 'err_console'
  end
  
  #
  # Initialize and enter the heartbeat loop.
  #
  ehb = AmazonSsaSupport::SsaHeartbeat.new(aws_args)
  ehb.start_heartbeat_loop
  
  #
  # Initialize the extractor and enter the main extraction loop.
  #
  eqe = AmazonSsaSupport::SsaQueueExtractor.new(aws_args)

  while true do
    tries = 0
    begin
      exit_code = eqe.extract_loop
      #
      # Determine how we should exit.
      #
      case exit_code
      when :exit
        #$log.info("Exiting")
        ehb.stop_heartbeat_loop
        lfo.flush
        #exit 0
        break
      when :reboot
        #$log.info "Rebooting"
        ehb.stop_heartbeat_loop
        lfo.flush
        `nohup shutdown -t0 -r now &`
      when :shutdown
        #$log.info "Shutting down"
        ehb.stop_heartbeat_loop
        lfo.flush
        `nohup shutdown -t0 -h now &`
      end
    rescue => err
      $log.error(err.backtrace.join("\n"))
    end

  end
end
