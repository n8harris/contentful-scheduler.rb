$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'contentful/scheduler'
require 'contentful/webhook/listener'
require 'json'

class MockServer
  def [](key)
    nil
  end
end

class MockRequest
end

class MockResponse
  attr_accessor :status, :body
end

class RequestDummy
  attr_reader :topic, :body

  def initialize(topic, body)
    @topic = topic
    @body = JSON.dump(body)
  end

  def [](key)
    topic if key == 'X-Contentful-Topic'
  end
end

class Contentful::Webhook::Listener::Controllers::Wait
  @@sleeping = false

  def sleep(time)
    @@sleeping = true
  end

  def self.sleeping
    value = @@sleeping
    @@sleeping = false
    value
  end
end
