
require 'date'
require 'net/https'
require 'pubnub'

module TradeBot
  class DataProcessingActor
    include Celluloid
    include Celluloid::Logger

    attr_reader :sub_redis, :stat_redis

    # Setup the data processing actor
    def initialize
      debug('Setting up the data processing actor.')

      @sub_redis  = TradeBot.new_redis_instance
      @stat_redis = TradeBot.new_redis_instance
    end

    # Begin procesing messages for statistical purposes
    def process
      debug('Subscription to local redis stream for data processing.')

      sub_redis.subscribe('pubnub:stream') do |on|
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
      # Extract all the relevant values
      instaneous_value = {}
      %w{ avg buy high last low sell vol vwap }.each do |s|
        instaneous_value[s.to_sym] = ticker[s]['value_int'].to_i
      end
      instaneous_value[:updated] = ticker['now'].to_i

      # Store the current values in redis
      stat_redis.pipelined do
        instaneous_value.each do |key, val|
          stat_redis.hset('trading:current', key, val)
        end
        stat_redis.zadd('trading:data', ticker['now'], JSON.generate(instaneous_value))
      end

      # Check to see if we need to process this minute's worth of data
      cur_time = Time.now.to_i
      minute_start = (Time.at(cur_time - (cur_time % 60))).to_i * 1e6

      start_value = (stat_redis.get('trading:processed:minutely') || 0).to_i
      return unless time = first_pending_time_from(start_value)

      # Loop through all the unprocessed data in minutely increments until we
      # reach the current start of a minute.
      while time <= minute_start
        # Get the data for this minute
        relevant = stat_redis.zrangebyscore('trading:data', time, time + (60 * 1e6))

        # If there isn't any data there is nothing to process
        if relevant.size == 0
          time += 60 * 1e6
          next
        end

        # Parse the relevant data from it's JSON, this dataset has values in
        # it we can't trust so we'll also remove those.
        relevant.map! { |d| JSON.parse(d) }
        relevant.each { |h| h.delete("low"); h.delete("high") }

        # Build our stats from the data we collected
        candlestick = build_candlestick(relevant, time)

        # Increment the time by a minute
        time += 60 * 1e6

        # Store that we've processed this minutes worth of information
        stat_redis.zadd('trading:candlestick:minutely', time, JSON.generate(candlestick))
        stat_redis.set('trading:processed:minutely', time.to_i)

        info(candlestick)
      end
    end

    # Build a candlestick dataset over the provided values and mark it with the
    # provided start time.
    def build_candlestick(dataset, time)
      # Initialize the candlestick data with known values
      cs = {
        close: dataset[-1]["close"] || dataset[-1]["last"],
        high:  dataset[0]["high"]   || dataset[0]["last"],
        low:   dataset[0]["low"]    || dataset[0]["last"],
        open:  dataset[0]["open"]   || dataset[0]["last"],
        time:  time.to_i
      }

      # Find the highs and lows for the period, we can't use the lows or highs
      # provided by in the stream as they're for much greater time periods.
      dataset.each do |d|
        cs["low"]  = d["last"] if d["last"] < cs["low"]
        cs["high"] = d["last"] if d["last"] < cs["high"]
      end

      # Build the count of values for future averaging
      cs["count"] = (dataset.map { |h| h.fetch("count", 0) }.inject(&:+))
      cs["count"] = dataset.count if cs["count"] == 0

      # Build the sum of values for current and future averaging
      cs["sum"] = (dataset.map { |h| h.fetch("sum", 0) }.inject(&:+))
      cs["sum"] = (dataset.map { |r| r["avg"] }.inject(&:+)) if cs["sum"] == 0

      # Straight-forward statistics
      cs["avg"] = cs["sum"] / cs["count"]
      cs["vol"] = dataset.map { |r| r["vol"] }.inject(&:+)

      cs
    end

    # Attempt to get the start time of any pending entries that need to be
    # processed. If there aren't any pending data chunks this will return
    # nil.
    #
    # @param [Fixnum] timestamp
    # @return [Nil,Fixnum]
    def first_pending_time_from(timestamp)
      pending = stat_redis.zrange("trading:data", timestamp, 1, with_scores: true)
      return (pending.empty? ? nil : pending[0][1])
    end

    def update_lag(lag)
    end
  end
end

