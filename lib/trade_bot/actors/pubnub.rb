
require 'net/https'
require 'pubnub'

module TradeBot
  class PubNubActor
    include Celluloid
    include Celluloid::Logger

    RELEVANT_CHANNELS = ['trade.lag', 'ticker.BTCUSD', 'depth.BTCUSD']

    # Initialize pubnub actor and push all of our messages into redis for later
    # processing.
    def initialize
      @channel_map = get_channels(RELEVANT_CHANNELS)
      @pubnub = Pubnub.new(
        logger: ::Logger.new('/dev/null'), # It's silly that the logger has to be disabled like this...
        subscribe_key: 'sub-c-50d56e1e-2fd9-11e3-a041-02ee2ddab7fe',
        ssl: false
      )

      redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      @redis = ::Redis.new(url: redis_url, driver: :celluloid)
    end

    # Helper method to get the UUIDs of the streams we're interest in from the
    # MtGox API.
    #
    # @param [Array<String>] List of neat channel names
    def get_channels(names = [])
      uri = URI.parse('https://mtgox.com/api/2/stream/list_public')
      channels = JSON.parse(Net::HTTP.get(uri))["data"]
      Hash[names.map { |n| [n, channels[n]] }.reject { |i| i[1].nil? }]
    end

    # Process a message received via a pubnub subscription.
    #
    # @param [Pubnub::Response]
    def handle_message(msg)
      encoded_msg = JSON.generate(msg.message)

      @redis.publish("tradebot:stream", encoded_msg)
      @redis.zadd("tradebot:history", Time.now.to_i, encoded_msg)
    rescue => e
      error("Error handling message from pubnub: #{e.message}")
    end

    # Subscribe to the channels relevant to the bot and process being
    # processing it's messages.
    def start
      @pubnub.subscribe(
        channels: @channel_map.values.join(","),
        callback: method(:handle_message),
        http_sync: false
      )
    end
  end
end

