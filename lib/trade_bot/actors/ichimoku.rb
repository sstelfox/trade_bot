
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
      @redis = TradeBot.new_redis_instance

      setup_bot(options.fetch(:usd_init, 0), options.fetch(:btc_init, 5))
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
    end

    # Remove this bot's settings from redis
    def clear_data
      @redis.del("bot:#{@name}:settings")
    end
  end
end

