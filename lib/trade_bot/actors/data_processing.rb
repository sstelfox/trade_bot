
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    # Setup the data processing actor
    def initialize
      debug('Setting up the DataProcessingActor')
      @redis = TradeBot.new_redis_instance
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
      redis = TradeBot.new_redis_instance

      %w{ avg buy high last low sell vol vwap }.each do |s|
        redis.hset('trading:current', s, ticker[s]['value_int'])
      end
      redis.hset('trading:current', 'updated', ticker['stamp'])

      info(redis.hgetall('trading:current'))
    end

    def update_lag(lag)
    end
  end
end

