# frozen_string_literal: true

module Msir
  class JetStreamCunsomer 
    private

    attr_reader :processor, :pull_subscribe

    public

    def initialize(processor:)
      @processor = processor

      connect = NATS.connect(
        servers: Msir.config.nats_servers,
        dont_randomize_servers: true,
        reconnect_time_wait: Msir.config.nats_reconnect_time_wait,
        max_reconnect_attempts: Msir.config.nats_max_reconnect_attempts
      )
      Msir.logger.write(:info, "Connected to #{connect.connected_server}")

      jet_stream = connect.jetstream
      jet_stream.add_stream(name: Msir.config.nats_stream, subjects: [Msir.config.nats_subject])
      @pull_subscribe = jet_stream.pull_subscribe(Msir.config.nats_subject, Msir.config.nats_durable)
    end

    def run
      while true do
        begin
          messages = pull_subscribe.fetch(Msir.config.nats_fetch_at_once)
          tracer = OpenTelemetry.tracer_provider.tracer('my_tracer')
          tracer.in_span('process_message') do |span|
            process_messages(messages)
          end
        rescue NATS::IO::Timeout
          next
        end
      end
    end

    private

    def process_messages(messages)
      messages.each do |message|
        Msir.logger.write(:info, "#{Time.now} - Received: #{message}")
          msg = message.data
          raise EmptyMessageError if msg.empty?
          processor.process(msg)
          message.ack
      end
    rescue StandardError => e
      Msir.logger.write(:error, "Cant`t send the message - #{e}")
    end
  end
end
