
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    # Setup the data processing actor
    def initialize
      debug('Setting up the data processing actor.')
      @redis = TradeBot.new_redis_instance
    end

    # Begin procesing messages for statistical purposes
    def process
      debug('Subscription to local redis stream for data processing.')

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

    # Process ticker messages we've received from the pubnub stream.
    #
    # @param [Hash<String => String>] ticker
    def update_ticker(ticker)
      redis = TradeBot.new_redis_instance

      # Extract all the relevant values
      instaneous_value = {}
      %w{ avg buy high last low sell vol vwap }.each do |s|
        instaneous_value[s.to_sym] = ticker[s]['value_int'].to_i
      end
      instaneous_value[:updated] = ticker['now'].to_i

      # Store the current values in redis
      redis.pipelined do
        instaneous_value.each do |key, val|
          redis.hset('trading:current', key, val)
        end
        redis.zadd('trading:data', ticker['now'], JSON.generate(instaneous_value))
      end

      info(instaneous_value)
    end

    def update_lag(lag)
    end
  end
end

