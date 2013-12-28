
require 'trade_bot/pubnub/configuration'
require 'trade_bot/pubnub/client'
require 'trade_bot/pubnub/crypto'
require 'trade_bot/pubnub/errors'

module TradeBot::PubNub
  # Shortcut function to create a client
  def self.new(*args)
    TradeBot::PubNub::Client.new(*args)
  end
end

