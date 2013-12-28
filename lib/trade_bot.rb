
# Ruby core
require 'uri'

# Gems
require 'celluloid'
require 'celluloid/io'
require 'celluloid/redis'

# Local requires
require 'trade_bot/actors/pubnub'
require 'trade_bot/version'

# We don't need no objects let the mother **** burn
JSON.create_id = nil

module TradeBot
end

