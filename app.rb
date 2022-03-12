# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
Bundler.require(:default, ENV['APP_ENV'] || :development)

require 'nats/client'
require 'opentelemetry/sdk'
require 'opentelemetry/exporter/otlp'
require 'opentelemetry-instrumentation-faraday'
require 'telegram/bot'
require 'logger'

require_relative 'msir_config'
require_relative 'msir_log'
require_relative 'msir_sender'
require_relative 'msir_errors'
require_relative 'msir_jet_stream_cunsomer'

OpenTelemetry::SDK.configure do |c|
  c.service_name = Msir.config.otel_service_name
  c.use 'OpenTelemetry::Instrumentation::Faraday'
end

Msir::JetStreamCunsomer.new(processor: Msir::Sender.new).run
