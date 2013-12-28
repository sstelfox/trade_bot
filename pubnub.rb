
require 'json'
require 'net/https'
require 'uri'
require 'websocket/driver'

class WS
  attr_reader :url

  def initialize(uri)
    @uri = uri
    @url = @uri.to_s

    puts "Setting up websocket"

    @driver = WebSocket::Driver.client(self)
    @socket = TCPSocket.new(@uri.host, @uri.port || 443)
  end

  def parse(data)
    @driver.parse(data)
  end

  def receive
    @socket.readpartial(1024)
  rescue
    ""
  end

  def send(message)
    @driver.text(message)
  end

  def start
    puts "Starting websocket"
    @driver.start
  end

  def write(data)
    @socket.write(data)
  end
end

w = WS.new(URI.parse('https://pubsub.pubnub.com'))

loop do
  puts w.receive
end
