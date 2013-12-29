
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
      end

      # Setup the destination statistics key
      base_key = 'trading:candlesticks'
      start_key = (base_key + ':start')
      current_key = (base_key + ':current')

      # Build up the hour we'll be collecting stats for
      current_time = Time.now.to_i
      hour_start = Time.at(current_time - (current_time % 3600)).to_datetime

      redis.pipelined do
        # We don't want to make any changes if our start_key changes
        redis.watch(start_key)
        existing_time = redis.get(start_key)

        if existing_time && (et = DateTime.parse(existing_time)) < hour_start
          new_historical_set = base_key + et.strftime("%Y%m%d%H")
          redis.rename(current_key, new_historical_set)
          redis.zadd(base_key + ':sets', new_historical_set)
          redis.set(start_key, hour_start.iso8601)

          # TODO process new historical set into candlestick data
        end
      end

      info(instaneous_value)
    end

    def update_lag(lag)
    end
  end
end

