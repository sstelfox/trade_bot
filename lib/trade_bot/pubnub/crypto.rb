
require 'base64'
require 'json'
require 'openssl'

module TradeBot::PubNub
  module Crypto
    CIPHER = 'AES-256-CBC'
    IV     = '0123456789012345'

    # Attempt to decrypt the provided cipher text with the provided key.
    #
    # @param [String] key
    # @param [String] cipher_text
    # @return [Object]
    def decrypt(key, cipher_text)
      raw = Base64.decode64(cipher_text)

      ciph = build_cipher(key)
      ciph.decrypt

      decrypted_string = (ciph.update(raw) + ciph.final).strip

      # This is kind of a hack, the contents are either a plaintext string (in
      # which case it'll be invalid JSON) or it'll be JSON.
      JSON.parse(decrypted_string) rescue decrypted_string
    rescue => e
      "Decryption/Parse Error: #{e}"
    end

    # Encrypt the provided message with the key, if the message is a complex
    # object it will be JSON encoded before being encrypted. The output will be
    # base64 encoded.
    #
    # @param [String] key
    # @param [String,Object] message
    # @return [String]
    def encrypt(key, message)
      plaintext = (message.is_a?(String) ? message : JSON.generate(message))

      ciph = build_cipher(key)
      ciph.encrypt

      Base64.encode64(ciph.update(plaintext) + ciph.final)
    rescue => e
      "Encryption Error: #{e}"
    end

    # Build and setup an instance of an OpenSSL cipher setup for use for either
    # encryption or decryption.
    #
    # @param [String] key
    # @return [OpenSSL::Cipher]
    def build_cipher(key)
      ciph = OpenSSL::Cipher::Cipher.new(CIPHER)
      ciph.iv = IV
      ciph.key = Digest::SHA256.hexdigest(key).slice(0,32)
      ciph
    end

    module_function :decrypt, :encrypt, :build_cipher
  end
end

