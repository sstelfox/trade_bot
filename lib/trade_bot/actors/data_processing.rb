
require 'date'
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

      # Check to see if we need to process this minute's worth of data
      cur_time = Time.now.to_i
      minute_start = Time.at(cur_time - (cur_time % 60))

      # Either no data has been processed, or at least one minute has passed
      # and data needs to be processed.
      last_minute_processed = redis.get('trading:processed:minutely')
      if last_minute_processed.nil? || minute_start >= Time.parse(last_minute_processed)
        # Figure out the time score of the first entry needing processing
        start_value = (last_minute_processed ? (Time.parse(last_minute_processed).to_i * 1e6).to_i : 0)
        _, time = redis.zrange("trading:data", start_value, 1, with_scores: true).first

        info(time.to_i)
        info((minute_start.to_i * 1e6).to_i)
        #while time <= (minute_start.to_i * 1e6)
          relevant = redis.zrangebyscore('trading:data', time, time + (60 * 1e6))
          info(relevant.size)

          # Increment to the next 60 seconds
          time += 60 * 1e6
        #end
      end

      info(instaneous_value)
    end

    def update_lag(lag)
    end
  end
end

