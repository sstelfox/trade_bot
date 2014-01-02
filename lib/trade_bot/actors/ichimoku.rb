
require 'net/https'
require 'pubnub'

module TradeBot::Actors
  class Ichimoku
    include Celluloid
    include Celluloid::Logger

    # Setup and initialize the bot.
    #
    # @param [String] name A unique name for an instance of this bot
    # @param [Hash] options A hash of various options to setup the bot
    def initialize(name, options = {})
      debug('Setting up the icimoku bot actor')

      @name = name.downcase.scan(/[a-z]/i).join
      @redis = TradeBot.redis
      @ichi  = TradeBot::Ichimoku.new(8, 11, 22)

      @settings = {
        'acceleration'     => 0.025,
        'max_acceleration' => 0.15,
        'pos'              => false
      }

      setup_bot(options.fetch(:usd_init, 0), options.fetch(:btc_init, 5))
    end

    def process
      cur = @ichi.current

      diff = 100 * ((cur['tenkan'] - cur['kijun']) / ((cur['tenkan'] + cur['kijun']) / 2))
      diff = diff.abs

      min_tenkan = [cur['tenkan'], cur['kijun']].min
      max_tenkan = [cur['tenkan'], cur['kijun']].max

      min_senkou = [cur['senkou_a'], cur['senkou_b']].min
      max_senkou = [cur['senkou_a'], cur['senkou_b']].max

      high = @candles.map { |c| c['high'] }
      low  = @candles.map { |c| c['low']  }

      psar_results = TradeBot::Math.psar(high, low, 0, (high.size - 1),
        @settings['acceleration'], @settings['max_acceleration'])

      sar = psar_results.last

      if diff >= @candles.last['close']
        if (@settings['pos'] == :long) && (cur['tenkan'] < cur['kijun']) && (cur['chikou'] < sar)
          sell
        elsif (@settings['pos'] == :short) && (cur['tenkan'] > cur['kijun']) && (cur['chikou'] > cur['lag_chikou'])
          buy
        end
      end

      if diff >= @candles.last['open']
        if (cur['tenkan'] > cur['kijun']) && (min_kenkan > max_senkou) && (cur['chikou'] > cur['lag_chikou'])
          info("Switching to the long position")
          @settings['pos'] = :long
          buy
        elsif (cur['tenkan'] < cur['kijun']) && (max_tenkan < min_senkou) && (cur['chikou'] < cur['lag_chikou'])
          info('Switching to the short position')
          @settings['pos'] = :short
          sell
        end
      end
    end

    def buy
      btc = @redis.hget("bot:#{@name}:settings", 'current:btc')
      cash = @redis.hget("bot:#{@name}:settings", 'current:usd')
      price = @candles.last['avg']

      new_btc = (cash / price).floor
      total_cost = (new_btc * price).floor
      usd = (cash - total_cost)

      @redis.hset("bot:#{@name}:settings", 'current:btc', new_btc + btc)
      @redis.hset("bot:#{@name}:settings", 'current:usd', usd)

      info('Purchased %f bitcoins at %0.2f for a total of %0.2f' % [(btc / 1e8), (price / 1e5), (total_cost / 1e5)])
    end

    def sell
      btc = @redis.hget("bot:#{@name}:settings", 'current:btc')
      cash = @redis.hget("bot:#{@name}:settings", 'current:usd')
      price = @candles.last['avg']

      new_cash = ((btc / 1e8) * price).floor
      sold_btc = (new_cache / price).floor
      remaining_btc = btc - sold_btc

      @redis.hset("bot:#{@name}:settings", 'current:btc', remaining_btc)
      @redis.hset("bot:#{@name}:settings", 'current:usd', cash + new_cash)

      info('Sold %f bitcoins at %0.2f for a total of %0.2f' % [(sold_btc / 1e8), (price / 1e5), (new_cash / 1e5)])
    end

    def push(data)
      @candles.push(data)
      @ichi.push(data)
    end

    # Sets up required values within the redis store for this bot, mostly
    # currency values
    #
    # @param [Fixnum] usd
    # @param [Fixnum] btc
    def setup_bot(usd, btc)
      @redis.pipelined do
        @redis.hsetnx("bot:#{@name}:settings", 'start:usd', usd * 1e5)
        @redis.hsetnx("bot:#{@name}:settings", 'start:btc', btc * 1e8)
        @redis.hsetnx("bot:#{@name}:settings", 'start:time', Time.now.to_f)

        @redis.hsetnx("bot:#{@name}:settings", 'current:usd', usd * 1e5)
        @redis.hsetnx("bot:#{@name}:settings", 'current:btc', btc * 1e8)
      end

      # Use the 15 minute candlestick data
      @candles = (@redis.zrange('trading:candlestick:900', 0, -1) || []).map { |d| JSON.parse(d) }

      # No more setup to do if we don't have any data
      return if @candles.empty?

      info('Starting bot %s run with %0.2f bitcoins, %0.2f cash' % [@name, btc, usd])

      @candles.each do |c|
        push(c)
        process if @ichi.has_enough_data?
      end
    end
  end
end

