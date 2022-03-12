# frozen_string_literal: true
require 'anyway_config'

module Msir
  class Config < Anyway::Config 
    MSIR_NATS_SERVERS = ['nats://127.0.0.1:4222']
    MSIR_NATS_RECONNECT_TIME_WAIT = 0.5
    MSIR_NATS_MAX_RECONNECT_ATTEMPTS = 2
    MSIR_NATS_MESSENGER_STREAM = 'messenger'
    MSIR_NATS_MESSENGER_SUBJECT = 'inbox'
    MSIR_NATS_MESSENGER_DURABLE = 'messenger_cunsomer'
    MSIR_NATS_FETCH_AT_ONCE = 5

    config_name :msir

    attr_config(
      :telegram_token,
      :telegram_chat_id,
      nats_servers: MSIR_NATS_SERVERS,
      nats_reconnect_time_wait: MSIR_NATS_RECONNECT_TIME_WAIT, 
      nats_max_reconnect_attempts: MSIR_NATS_MAX_RECONNECT_ATTEMPTS,
      nats_stream: MSIR_NATS_MESSENGER_STREAM, 
      nats_subject: MSIR_NATS_MESSENGER_SUBJECT, 
      nats_durable: MSIR_NATS_MESSENGER_DURABLE, 
      nats_fetch_at_once: MSIR_NATS_FETCH_AT_ONCE,
      otel_service_name: 'msir_messenger',
    )

    required :telegram_token, :telegram_chat_id

    coerce_types nats_servers: {type: :string, array: true}
  end

  def self.config
    @config ||= Config.new 
  end
end
