
module TradeBot
  class WebSocketActor
    include Celluloid
    include Celluloid::Logger

    MTGOX_WEBSOCKET_URL = URI.parse('https://socketio.mtgox.com/mtgox')

    def initialize
      redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')

      #@redis = Redis.new(driver: :celluloid, url: redis_url)
      @websocket = Celluloid::WebSocketClient.new(MTGOX_WEBSOCKET_URL, current_actor)
    end

    def on_close
      warn("MtGox Connection Closed: #{code.inspect}, #{reason.inspect}")
    end

    def on_message(data)
      #@redis.lpush("mtgox:raw:history", JSON.generate(data))
      #@redis.publish("mtgox:raw:stream", JSON.generate(data))
      info(JSON.generate(data))
    end

    def on_open
      debug("Opened MtGox WebSocket Connection.")
    end
  end
end

