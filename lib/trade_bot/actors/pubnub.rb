
require 'net/https'

module TradeBot
  class PubNubActor
    include Celluloid
    include Celluloid::Logger

    def initialize
      @pubnub = TradeBot::PubNub.new()
    end
  end
end

