module Onion
  module Layers
    class Three < Base
      include Singleton

      class XorDecode
        KNOWN_KEY =
          [
            0x6c, 0x24, 0x84, 0x8e, 0x42, 0x19, 0xa8, 0xe1, 0xc5, 0xdb, 0x57, 0x65, 0xb9, 0xc6, 0x14, 0x9e,
            0xa5, 0x19, 0x35, 0x96, 0x3b, 0x39, 0x7f, 0xa5, 0x65, 0xd1, 0xfe, 0x01, 0x85, 0x7d, 0xd9, 0x4c
          ]

        class << self
          def call(bytes)
            decrypt(bytes: bytes, key: reveal_key(bytes))
          end

          def decrypt(bytes:, key:)
            bytes.zip(key.cycle).map { |cipher_byte, key_byte| cipher_byte ^ key_byte }
          end

          def reveal_key(bytes)
            case ENV["LIVE_DECRYPT"].presence.try(:downcase)
            when "repl"
              Repl.new(bytes).reveal_key
            else
              KNOWN_KEY
            end
          end
        end
      end

      inside Two

      transform Ascii85::Decode
      transform XorDecode
    end
  end
end

require_relative "three/repl"
