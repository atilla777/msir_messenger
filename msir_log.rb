# frozen_string_literal: true

module Msir
  class Log
    private

    attr_reader :logger

    public

    def initialize
      @logger = Logger.new('/proc/1/fd/1')
    end

    def write(level, message)
      logger.send(level, message)
    end
  end

  def self.logger
    @logger || Log.new
  end
end
