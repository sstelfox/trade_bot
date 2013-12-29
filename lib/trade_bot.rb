
# Ruby core
require 'uri'

# Gems
require 'celluloid'
require 'celluloid/io'
require 'celluloid/redis'

# Local requires
require 'trade_bot/actors'
require 'trade_bot/helpers'
require 'trade_bot/version'

# We don't need no objects let the mother **** burn
JSON.create_id = nil

module TradeBot
  def self.new_redis_instance
    redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
    ::Redis.new(url: redis_url, driver: :celluloid)
  end
end

