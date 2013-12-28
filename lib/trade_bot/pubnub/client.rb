
module TradeBot::PubNub
  class Client
    def initialize(options = {})
      @channels      = {}

      @logger        = options.fetch(:logger, DEFAULT_CONFIGURATION[:logger])
      @origin        = options.fetch(:origin, DEFAULT_CONFIGURATION[:origin])

      @publish_key   = options.fetch(:publish_key,   DEFAULT_CONFIGURATION[:publish_key])
      @subscribe_key = options.fetch(:subscribe_key, DEFAULT_CONFIGURATION[:subscribe_key])

      @auth_key      = options.fetch(:secret_key, nil)
      @cipher_key    = options.fetch(:cipher_key, nil)
    end
  end
end

