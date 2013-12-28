
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    # Setup the data processing actor
    def initialize
      debug('Setting up the DataProcessingActor')

      redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      @redis = ::Redis.new(url: redis_url, driver: :celluloid)
    end

    # Begin procesing messages for statistical purposes
    def process
      info('Setting up subscription to local streams')

      @redis.subscribe('pubnub:stream') do |on|
        on.message { |_, msg| handle_message(msg) }
      end
    end

    # Process messages received through the redis subscription.
    #
    # @param [String] msg
    def handle_message(msg)
      info("Received message: #{JSON.parse(msg)}")
    rescue => e
      error("Error handling history message: #{e.message}")
    end
  end
end

