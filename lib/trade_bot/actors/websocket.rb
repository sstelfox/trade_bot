
require 'net/https'

module TradeBot
  class WebSocketActor
    include Celluloid
    include Celluloid::Logger

    BASE_SITE  = 'https://socketio.mtgox.com/mtgox'
    SOCKET_URL = 'wss://socketio.mtgox.com/socket.io/1/websocket/'

    attr_reader :url

    def initialize
      @url = SOCKET_URL + websocket_token
      @uri = URI.parse(@url)

      info("Websocket URI: #{@uri}")

      @driver = WebSocket::Driver.client(self)
      @socket = Celluloid::IO::TCPSocket.new(@uri.host, @uri.port || 443)

      #redis_url = (ENV['REDIS_PROVIDER'] || 'redis://127.0.0.1:6379/0')
      #@redis = Redis.new(driver: :celluloid, url: redis_url)

      @driver.on(:message) { |e| info(e.data) }
      @driver.on(:open) { |e| info("Opened: #{e.inspect}") }
      @driver.on(:error) { |e| info("Error: #{e.inspect}") }
      @driver.on(:close) { |e| info("Closed: #{e.inspect}") }
      @driver.start

      send("1::#{@uri.path}")

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

    private

    # Socket.io doesn't provide a straight websocket interface, instead you
    # negotiate a one-time session key for a websocket and use that too
    # connect. This method takes the public address MtGox provides and collects
    # a websocket token that can be used to establish a token.
    #
    # @return [String] websocket authentication token
    def websocket_token
      uri = URI.parse(BASE_SITE)
      uri.path = '/socket.io/1'
      uri.query = "t=#{Time.now.to_i}"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      # TODO: Replace with StartSSL cert in config directory, it seems like the
      # current reason the certificate is failing to validate is due too an
      # expired certificate.
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE

      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)
      info(response.body)

      response.body.split(':').first
    rescue
      false
    end
  end
end

