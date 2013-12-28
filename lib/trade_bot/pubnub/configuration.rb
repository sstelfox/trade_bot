
module TradeBot::PubNub
  # TODO: Trim these down, my money is only a small portion of these are
  # actually needed.
  DEFAULT_CONFIGURATION = {
    callback: lambda { |d| puts d },
    logger: Logger.new($stdout),
    origin: 'pubsub.pubnub.com',
    publish_key: 'demo',
    subscribe_key: 'demo',
  }
end

