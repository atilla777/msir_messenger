# frozen_string_literal: true

require 'logger'
require 'nats/client'
require 'telegram/bot'

class Log
  private

  attr_reader :logger

  public

  def initialize
    @logger = Logger.new(STDOUT)
  end

  def write(level, message)
    logger.send(level, message)
  end
end

class JetStreamCunsomer 
  def initialize(config:, logger: , processor:)
    cluster_opts = {
      servers: config.nats_servers,
      dont_randomize_servers: true,
      reconnect_time_wait: config.nats_reconnect_time_wait,
      max_reconnect_attempts: config.nats_max_reconnect_attempts
    }

    connect = NATS.connect(cluster_opts)
    logger.write(:info, "Connected to #{connect.connected_server}")
    jet_stream = connect.jetstream
    jet_stream.add_stream(name: config.nats_stream, subjects: [config.nats_subject])
    pull_subscribe = jet_stream.pull_subscribe(config.nats_subject, config.nats_durable)

    while true do
      begin
        messages = pull_subscribe.fetch(config.nats_fetch_at_once)
      rescue NATS::IO::Timeout
        next
      end
      messages.each do |message|
        logger.write(:info, "#{Time.now} - Received: #{message}")
        processor.process(message.data)
        message.ack
      end
    end
  end
end

class Config
  MSIR_NATS_SERVERS = ['nats://127.0.0.1:4222']
  MSIR_NATS_RECONNECT_TIME_WAIT = 0.5
  MSIR_NATS_MAX_RECONNECT_ATTEMPTS = 2
  MSIR_NATS_MESSENGER_STREAM = 'messenger'
  MSIR_NATS_MESSENGER_SUBJECT = 'inbox'
  MSIR_NATS_MESSENGER_DURABLE = 'messenger_cunsomer'
  MSIR_NATS_FETCH_AT_ONCE = 5

  attr_reader :data

  def initialize
    data = {
      telegram_token: ENV['MSIR_TELEGRAM_TOKEN'],
      telegram_chat_id: ENV['MSIR_TELEGRAM_CHAT_ID'],
      nats_servers: ENV['MSIR_NATS_SERVERS']&.split(',') || MSIR_NATS_SERVERS,
      nats_reconnect_time_wait: ENV['MSIR_NATS_RECONNECT_TIME_WAIT'] || MSIR_NATS_RECONNECT_TIME_WAIT, 
      nats_max_reconnect_attempts: ENV['MSIR_NATS_MAX_RECONNECT_ATTEMPTS'] || MSIR_NATS_MAX_RECONNECT_ATTEMPTS,
      nats_stream: ENV['MSIR_NATS_MESSENGER_STREAM'] || MSIR_NATS_MESSENGER_STREAM, 
      nats_subject: ENV['MSIR_NATS_MESSENGER_SUBJECT'] || MSIR_NATS_MESSENGER_SUBJECT, 
      nats_durable: ENV['MSIR_NATS_MESSENGER_DURABLE'] || MSIR_NATS_MESSENGER_DURABLE, 
      nats_fetch_at_once: ENV['MSIR_NATS_FETCH_AT_ONCE'] || MSIR_NATS_FETCH_AT_ONCE
    }
    @data = Struct.new(*data.keys).new(*data.values)
  end
end

class Sender
  attr_reader :config

  def initialize(config)
    @config = config
  end

  def process(message)
    Telegram::Bot::Client.run(config.telegram_token) do |bot|
      bot.api.send_message(chat_id: config.telegram_chat_id, text: message) 
    end
  end
end

config = Config.new.data

JetStreamCunsomer.new(
  config: config,
  logger: Log.new,
  processor: Sender.new(config)
)

