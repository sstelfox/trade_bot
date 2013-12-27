
require 'openssl'

module TradeBot::PubNub
  module Crypto
    CIPHER = 'AES-256-CBC'
    IV     = '0123456789012345'

    def decrypt(key, message)
    end

    def encrypt(key, message)
    end

    def build_key(key)
      Digest::SHA256.hexdigest(key).slice(0,32)
    end

    module_function :decrypt, :encrypt, :build_key
  end
end

