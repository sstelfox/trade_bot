
require 'json'
require 'net/https'
require 'uri'
require 'websocket/driver'

module MessageParser
  REGEX = /([^:]+):([0-9]+)?(\+)?:([^:]+)?:?([\s\S]*)?/

  # returns hash as {type: '1', id: '1', end_point: '4', data: [{key: value}]}
  def decode(string)
    (pieces = string.match(REGEX)) ? format(pieces) : {type: '0'}
  end

  def format(pieces)
    {type: pieces[1], id: pieces[2], end_point: pieces[4], data: pieces[5]}
  end

  module_function :decode, :format
end

module UnvalidatedGet
  def perform(uri)
    puts "Getting connection: #{uri}"

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true

    # The cert is expired on our primary connection, until that is changed we
    # need to disable verification to make a connection at all.
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE

    response = http.request(Net::HTTP::Get.new(uri.request_uri))
    response.body
  end

  module_function :perform
end

module Session
  def format_url(url)
    uri = URI.parse(url)
    uri.path = '/socket.io/1/'
    uri.port = uri.port || 443
    uri.query = "t=#{Time.now.to_i}"
    uri
  end

  def get_session(url)
    puts "Getting session ID"
    UnvalidatedGet.perform(format_url(url)).split(':')
  end

  module_function :format_url, :get_session
end

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

class SocketIOClient
  def connect_transport
    unless @transports.include?('websocket')
      raise "The target server doesn't support websockets."
    end

    puts "Connecting transport"

    conn = @uri.dup
    conn.scheme = (@uri.scheme == 'https') ? 'wss' : 'ws'
    conn.port = (conn.scheme == 'wss') ? 443 : 80
    conn.path = "/socket.io/1/websocket/#{@session_id}"

    @transport = WS.new(conn)
    @transport.send("1::#{@uri.path}")
  end

  def initialize(url)
    @uri = URI.parse(url)
    session_values = Session.get_session(url)

    @session_id         = session_values[0]
    @heartbeat_timeout  = session_values[1]
    @connection_timeout = session_values[2]
    @transports         = session_values[3].split(',')

    puts "Setup complete"
  end

  def join
    @thread.join
  end

  def send_heartbeat
    puts "Sending heartbeat"
    @transport.send("2::")
  end

  def start
    connect_transport
    start_receive_loop
    self
  end

  def start_receive_loop
    @thread = Thread.new do
      loop do
        data = @transport.receive
        decoded = MessageParser.decode(data)

        case decoded[:type]
        when '0'
          @on_disconnect.call if @on_disconnect
        when '1'
          @on_connect.call if @on_connect
        when '2'
          send_heartbeat
        when '3'
          @on_message.call(decoded[:data]) if @on_message
        when '4'
          @on_json_message.call(decoded[:data]) if @on_json_message
        when '5'
          message = JSON.parse(decoded[:data])
          @on_event[message['name']].call(message['args']) if @on_event[message['name']]
        when '6'
          @on_ack.call if @on_ack
        when '7'
          @on_error.call(decoded[:data]) if @on_error
        when '8'
          @on_noop.call if @on_noop
        end
      end
    end

    @thread
  end
end

puts "Beginning the game..."

sioc = SocketIOClient.new('https://socketio.mtgox.com/')
sioc.start.join

