
module TradeBot
  class WebSocketActor
    include Celluloid
    include Celluloid::Logger

    attr_reader :url

    def initialize
      @url = 'https://socketio.mtgox.com/mtgox'
      @url = 'http://websocket.mtgox.com/mtgox'
      @uri = URI.parse(url)

      @driver = WebSocket::Driver.client(self)
      @socket = Celluloid::IO::TCPSocket.new(@uri.host, @uri.port)

      #redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      #@redis = Redis.new(driver: :celluloid, url: redis_url)

      @driver.on(:message) { |e| info(e.data) }

      @driver.start
      loop { parse(@socket.read) }
    end

    def parse(data)
      @driver.parse(data)
    end

    def send(message)
      @driver.text(message)
    end

    def write(data)
      @socket.write(data)
    end

    def on_message(event)
      #@redis.lpush("mtgox:raw:history", JSON.generate(data))
      #@redis.publish("mtgox:raw:stream", JSON.generate(data))
      info(event.inspect)
    end
  end
end

