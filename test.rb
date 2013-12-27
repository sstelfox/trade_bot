# encoding: ascii

require 'SocketIO'

client = SocketIO.connect('https://socketio.mtgox.com/') do
  before_start do
    on_message { |m| puts m }
  end
end

client.join
