require 'date'
require 'resque'
require 'redis'
require 'logger'
require 'contentful/webhook/listener'

require_relative 'scheduler/controller'
require_relative 'scheduler/version'

module Contentful
  module Scheduler
    DEFAULT_PORT = 32123
    DEFAULT_ENDPOINT = '/scheduler'
    DEFAULT_LOGGER = ::Contentful::Webhook::Listener::Support::NullLogger.new

    @@config = nil

    def self.config=(config)
      fail ':redis configuration missing' unless config.key?(:redis)
      fail ':spaces configuration missing' unless config.key?(:spaces)
      config[:spaces].each do |space, data|
        fail ":management_token missing for space: #{space}" unless data.key?(:management_token)
      end

      config[:port] = (ENV.key?('PORT') ? ENV['PORT'].to_i : DEFAULT_PORT) unless config.key?(:port)
      config[:logger] = DEFAULT_LOGGER unless config.key?(:logger)
      config[:endpoint] = DEFAULT_ENDPOINT unless config.key?(:endpoint)

      ::Resque.redis = config[:redis].dup
      @@config ||= config
    end

    def self.config
      @@config
    end

    def self.start(config = {})
      fail "Scheduler not configured" if self.config.nil? && !block_given?

      if block_given?
        yield(config) if block_given?
        self.config = config
      end

      ::Contentful::Webhook::Listener::Server.start do |config|
        config[:port] = self.config[:port]
        config[:logger] = self.config[:logger]
        config[:endpoints] = [
          {
            endpoint: self.config[:endpoint],
            controller: ::Contentful::Scheduler::Controller,
            timeout: 0
          }
        ]
      end.join
    end
  end
end
