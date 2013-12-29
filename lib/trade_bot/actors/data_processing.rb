
require 'date'
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    attr_reader :redis

    # Build a candlestick data point from the provided source key, the start and
    # end time.
    #
    # @param [String] source_key The redis key holding the zset that will be the
    #   source of our data.
    # @param [Fixnum] start_time
    # @param [Fixnum] end_time
    # @return [Hash<String => String>]
    def build_candlestick(source_key, start_time, end_time)
      data = redis.zrangebyscore(source_key, start_time, end_time)
      data.map! { |d| JSON.parse(d) }

      return if data.empty?

      # Initialize the candlestick data
      cs = {
        "close"    => relevant[-1]["last"],
        "high"     => relevant[0]["last"],
        "interval" => (end_time - start_time),
        "low"      => relevant[0]["last"],
        "open"     => relevant[0]["last"],
        "time"     => start_time
      }

      # Find the highs and lows for the period
      data.each do |d|
        cs["low"]  = d["low"]  if d["low"]  < cs["low"]
        cs["high"] = d["high"] if d["high"] > cs["high"]
      end

      # Calculate the average of the averages
      cs["avg"] = (data.map { |r| r["last"] }.inject(&:+)) / data.size

      cs
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

    # Setup the data processing actor
    def initialize
      debug('Setting up the data processing actor.')

      @redis_subscription = TradeBot.new_redis_instance
      @redis = TradeBot.new_redis_instance
    end

    # Begin procesing messages for statistical purposes
    def process
      debug('Subscription to local redis stream for data processing.')

      @redis_subscription.subscribe('pubnub:stream') do |on|
        on.message { |_, msg| handle_message(msg) }
      end
    end

    # Parse raw ticker information into only the metrics that are valuable to
    # us.
    #
    # @param [Hash<String => String>] raw_ticker
    # @return [Hash<String => String>]
    def parse_raw(raw_ticker)
      useful_data = {}
      %w{ avg buy high last low sell vol vwap }.each do |s|
        useful_data[s] = raw_ticker[s]['value_int'].to_i
      end
      useful_data['time'] = raw_ticker['now'].to_i
      useful_data
    end

    # Process ticker messages we've received from the pubnub stream.
    #
    # @param [Hash<String => String>] ticker
    def update_ticker(ticker)
      # Extract all the relevant values and store it in redis
      current = parse_raw(ticker)
      redis.zadd('trading:data', current['time'], JSON.generate(current))

      # Check to see if we need to process this minute's worth of data
      cur_time = Time.now.to_i
      minute_start = (Time.at(cur_time - (cur_time % 60))).to_i * 1e6

      # Either no data has been processed, or at least one minute has passed
      # and data needs to be processed.
      last_minute = (redis.get('trading:processed:minutely') || 0).to_i
      if minute_start > last_minute

        # See if there are pending entries in need of processing
        #pending = redis.zrange("trading:data", start_value, 1, with_scores: true)
        #return if pending.empty?
        #time = pending[0][1]

        # Build the candlestick data for the minute periods we're in
        #cs = build_candlestick('trading:data', period_start, period_end)
        #redis.zadd('trading:candlestick:minutely', time, JSON.generate(cs))
        #redis.set('trading:processed:minutely', period_end)

        #info(cs)
      end
    end

    def update_depth(depth)
    end

    def update_lag(lag)
    end
  end
end

