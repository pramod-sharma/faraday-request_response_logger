require 'faraday'
require 'logger'

module Faraday
  module RequestResponseLogger
    class Middleware  < Faraday::Response::Middleware

      extend Forwardable

      def_delegators :@logger, :debug, :info, :warn, :error, :fatal

      def initialize(app, options = {})
        @app = app
        @logger = options.fetch(:logger) {
          require 'logger'
          ::Logger.new($stdout)
        }
        @logger_level = options.fetch(:logger_level) { 'debug' }
        @seperator = options.fetch(:seperator) { nil }
      end

      def call(env)
        @logger.send(@logger_level) { @seperator } if @seperator

        # Request Logging
        @logger.send(@logger_level) { "\n\nRequest Log" }
        @logger.send(@logger_level) { "#{ env[:method].upcase } #{ env[:url] }" }
        @logger.send(@logger_level) { curl_output(env[:request_headers], env[:body]).inspect }

        # Response Logging
        @logger.send(@logger_level) { "\n\nResponse Log" }
        @app.call(env).on_complete do
          @logger.send(@logger_level, "#{ response_values(env) }")
          @logger.send(@logger_level, "#{ @seperator }") if @seperator
        end
      end

      private
        def response_values(env)
          { status: env.status, headers: env.response_headers, body: env.body }
        end

        def curl_output(headers, body)
          string = headers.collect { |k,v| "#{k}: #{v}" }.join("\n")
          string + "\n\n#{body}"
        end
    end
  end
end
