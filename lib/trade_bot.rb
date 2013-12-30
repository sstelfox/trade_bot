
# Ruby core
require 'uri'
require 'json'

# Gems
require 'celluloid'
require 'celluloid/io'
require 'celluloid/redis'

# We don't need no objects let the mother **** burn
JSON.create_id = nil

module TradeBot
  def self.redis
    redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
    ::Redis.new(url: redis_url, driver: :celluloid)
  end
end

# Local requires
require 'trade_bot/actors'
require 'trade_bot/math'
require 'trade_bot/version'

