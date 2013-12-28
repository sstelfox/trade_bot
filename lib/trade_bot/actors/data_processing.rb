
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
      data = JSON.parse(msg)

      case data['channel_name']
      when 'depth.BTCUSD'
        update_depth(data['depth'])
      when 'ticker.BTCUSD'
        update_ticker(data['ticker'])
      when 'trade.lag'
        update_lag(data['lag'])
      end
    rescue => e
      error("Error handling stream message: #{e.message}")
    end

    def update_depth(depth)
    end

    def update_ticker(ticker)
      @redis.multi do
        @redis.hset('trading:current', 'high', ticker['high']['value_int'])
        @redis.hset('trading:current', 'last', ticker['last']['value_int'])
        @redis.hset('trading:current', 'low', ticker['low']['value_int'])
        @redis.hset('trading:current', 'avg', ticker['avg']['value_int'])
        @redis.hset('trading:current', 'vwap', ticker['vwap']['value_int'])
        @redis.hset('trading:current', 'vol', ticker['vol']['value_int'])
        @redis.hset('trading:current', 'buy', ticker['buy']['value_int'])
        @redis.hset('trading:current', 'sell', ticker['sell']['value_int'])
        @redis.hset('trading:current', 'updated', ticker['stamp'])
      end
    end

    def update_lag(lag)
    end
  end
end

