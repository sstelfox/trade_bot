
require 'net/https'
require 'uri'
require 'websocket/driver'

module MessageParser
  REGEX = /([^:]+):([0-9]+)?(\+)?:([^:]+)?:?([\s\S]*)?/

  # returns hash as {type: '1', id: '1', end_point: '4', data: [{key: value}]}
  def decode(string)
    (pieces = string.match(@regexp)) ? format(pieces) : {type: '0'}
  end

  def format(pieces)
    {type: pieces[1], id: pieces[2], end_point: pieces[4], data: pieces[5]}
  end

  module_function :decode, :format
end

module UnvalidatedGet
  def perform(uri)
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
    UnvalidatedGet.perform(format_url(url)).split(':')
  end

  module_function :format_url, :get_session
end

class Websocket
end

class SocketIOClient
  attr_reader :url

  def initialize(url)
    @url = url

    @uri = URI.parse(@url)
    session_values = Session.get_session(@url)

    @session_id         = session_values[0]
    @heartbeat_timeout  = session_values[1]
    @connection_timeout = session_values[2]
    @transports         = session_values[3].split(',')
  end

  def start
    connect_transport
    start_receive_loop
  end

  def connect_transport
    unless @transports.include?('websocket')
      raise "The target server doesn't support websockets."
    end

    conn = @uri.dup
    conn.scheme = (@uri.scheme == 'https') ? 'wss' : 'ws'
    conn.port = (conn.scheme == 'wss') ? 443 : 80
    conn.path = "/socket.io/1/websocket/#{@session_id}"
  end
end

sioc = SocketIOClient.new('https://socketio.mtgox.com/')
