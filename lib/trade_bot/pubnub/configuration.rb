
module TradeBot::PubNub
  # TODO: Trim these down, my money is only a small portion of these are
  # actually needed.
  DEFAULT_CONFIGURATION = {
    auto_reconnect: true,
    callback: lambda { |d| puts d },
    channel: 'hello_world',
    content_type: 'application/json',
    encoding: nil,
    headers: {},
    max_retries: 60,
    method: 'GET',
    origin: 'pubsub.pubnub.com',
    params: {},
    path: '/',
    periodic_timer: 0.25,
    port: 80,
    publish_key: 'demo',
    secret_key: 0,
    ssl_set: false,
    subscribe_key: 'demo',
    timeout: 5,
    time_token: 0,
    user_agent: "Pubnub Test Implementation #{::TradeBot::VERSION}"
  }
end

