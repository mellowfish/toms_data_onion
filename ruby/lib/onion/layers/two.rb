module Onion
  module Layers
    class Two < Base
      include Singleton

      module DiscardCorruptedBytes
        def self.call(data)
          data.select { |byte| parity_match?(byte) }
        end

        def self.parity_match?(byte)
          given_parity = byte & 1

          on_bits = 0
          on_bits += 1 if (byte & 2) > 0
          on_bits += 1 if (byte & 4) > 0
          on_bits += 1 if (byte & 8) > 0
          on_bits += 1 if (byte & 16) > 0
          on_bits += 1 if (byte & 32) > 0
          on_bits += 1 if (byte & 64) > 0
          on_bits += 1 if (byte & 128) > 0

          given_parity == on_bits & 1
        end
      end

      module CompactBytes
        def self.call(data)
          raise "parity failure" unless data.length % 8 == 0
          data.each_slice(8).flat_map { |short_bytes| compact_short_bytes(short_bytes) }
        end


        # |0123456?0123456?0123456?0123456?0123456?0123456?0123456?0123456?|
        # |0000000011111111222222223333333344444444555555556666666677777777|
        # |       p       p       p       p       p       p       p       p|
        # |1111111 1222222 2233333 3334444 4444555 5555566 6666667 7777777 |
        def self.compact_short_bytes(short_bytes)
          [
            ((short_bytes[0] & 0b11111110) << 0) | ((short_bytes[1] & 0b10000000) >> 7),
            ((short_bytes[1] & 0b01111110) << 1) | ((short_bytes[2] & 0b11000000) >> 6),
            ((short_bytes[2] & 0b00111110) << 2) | ((short_bytes[3] & 0b11100000) >> 5),
            ((short_bytes[3] & 0b00011110) << 3) | ((short_bytes[4] & 0b11110000) >> 4),
            ((short_bytes[4] & 0b00001110) << 4) | ((short_bytes[5] & 0b11111000) >> 3),
            ((short_bytes[5] & 0b00000110) << 5) | ((short_bytes[6] & 0b11111100) >> 2),
            ((short_bytes[6] & 0b00000010) << 6) | ((short_bytes[7] & 0b11111110) >> 1),
          ]
        end
      end

      inside One

      transform Ascii85::Decode
      transform DiscardCorruptedBytes
      transform CompactBytes
    end
  end
end
