
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    # Setup the data processing actor
    def initialize
      redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      @redis = ::Redis.new(url: redis_url, driver: :celluloid)

      process_interval
    end

    def process_interval
      @redis.subscribe('pubnub:stream') do |on|
        start_time = Time.now.to_i
        start_time -= (start_time % 60)

        info("Received message: #{msg}")
      end
    rescue => e
      error("Error handling history message: #{e.message}")
    end
  end
end

