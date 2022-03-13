# frozen_string_literal: true

module Msir
  class Log
    LOG_OUTPUT = if ENV['DOCKER_CONSOLE_LOGS'] == 'true'
      '/proc/1/fd/1'.freeze
    else
      STDOUT
    end

    private

    attr_reader :logger

    public

    def initialize
      @logger = Logger.new(LOG_OUTPUT)
      @logger.formatter = formatter
    end
    
    def write(level, message)
      logger.send(level, message)
    end
    
    private

    def formatter
      proc do |severity, datetime, progname, msg|
        date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
        JSON.dump(
          date: "#{date_format}",
          severity:"#{severity.ljust(5)}",
          pid:"##{Process.pid}",
          message: msg
        ) + "\n"
      end
    end
  end

  def self.logger
    @logger || Log.new
  end
end
