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

Dir[File.join(__dir__, 'msir', '**', '*.rb')].each { |file| require file }

OpenTelemetry::SDK.configure do |c|
  c.service_name = Msir.config.otel_service_name
  c.use 'OpenTelemetry::Instrumentation::Faraday'
end

module Msir; end

Msir::JetStreamCunsomer.new(processor: Msir::Sender).run
