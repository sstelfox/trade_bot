
module TradeBot::PubNub
  InitError      = Class.new(RuntimeError)
  PresenceError  = Class.new(RuntimeError)
  PublishError   = Class.new(RuntimeError)
  SubscribeError = Class.new(RuntimeError)

  OperationError = Class.new(RuntimeError) do
    def operation_exception
      PubNubRequest::RequestError
    end
  end
end
