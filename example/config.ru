require 'resque'
require 'resque/server'
require 'resque/scheduler/server'

config = {
  host: 'YOUR_REDIS_HOST',
  port: 'YOUR_REDIS_PORT',
  password: 'YOUR_REDIS_PASSWORD'
}
Resque.redis = config

run Rack::URLMap.new \
  "/" => Resque::Server.new
