require 'resque'
require 'redis'
require 'logger'
require 'contentful/webhook/listener'

require_relative 'scheduler/controller'
require_relative 'scheduler/version'

module Contentful
  module Scheduler
    @@config = nil

    def self.config=(config)
      fail ":redis configuration missing" unless config.key?(:redis)
      fail ":spaces configuration missing" unless config.key?(:spaces)
      fail ":management_token configuration missing" unless config.key?(:management_token)

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
        config[:port] = 32123
        config[:logger] = Logger.new(STDOUT)
        config[:endpoints] = [
          {
            endpoint: '/scheduler',
            controller: ::Contentful::Scheduler::Controller,
            timeout: 0
          }
        ]
      end.join
    end
  end
end
