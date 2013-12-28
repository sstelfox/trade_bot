
require 'net/https'
require 'pubnub'

module TradeBot
  class IchimokuActor
    include Celluloid
    include Celluloid::Logger

    def initialize(name, options = {})
      @name = name.downcase.scan(/[a-z]/i).join
      redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      @redis = ::Redis.new(url: redis_url, driver: :celluloid)

      setup_bot(options.fetch(:usd_init, 0), options.fetch(:btc_init, 5))
    end

    # Sets up required values within the redis store for this bot, mostly
    # currency values
    #
    # @param [Fixnum] usd
    # @param [Fixnum] btc
    def setup_bot(usd, btc)
      @redis.setnx("bot:#{@name}:usd", usd)
      @redis.setnx("bot:#{@name}:btc", btc)
      @redis.setnx("bot:#{@name}:start", Time.now.to_f)
    end
  end
end

