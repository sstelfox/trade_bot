
require 'websocket/driver'

class Celluloid::WebSocketClient
  include Celluloid::IO
  extend Forwardable

  attr_reader :url
  def_delegators :@client, :text, :ping, :close, :protocol

  def initialize(url, handler)
    @url = url
    uri = URI.parse(url)

    @socket = Celluloid::IO::TCPSocket.new(uri.host, uri.port)
    @client = WebSocket::Driver.client(@socket)
    @handler = handler

    # Trigger the run method in the background on this class
    async.run
  end

  def run
    @client.on('open') do |event|
      @handler.async.on_open if @handler.respond_to?(:on_open)
    end

    @client.on('message') do |event|
      @handler.async.on_message(event.data) if @handler.respond_to?(:on_message)
    end

    @client.on('close') do |event|
      @handler.async.on_close(event.code, event.reason) if @handler.respond_to?(:on_close)
    end

    @client.on('error') do |event|
      @handler.async.on_error('') if @handler.respond_to?(:on_error)
    end

    @client.start

    loop do
      @client.parse(@socket.readpartial(1024))
    end
  end

  def write(buffer)
    self.text(buffer)
  end
end

