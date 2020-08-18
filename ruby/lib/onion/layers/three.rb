module Onion
  module Layers
    class Three < Base
      include Singleton

      # Idea: come back and build a decryptor CLI tool,
      # basically a thing that shows the hex/plaintext data (a la hexedit)
      # and you guess plaintext a character at a time to build up the key.
      #
      # This is what I did, but with a bunch of hacky code and a zillion passthroughs.
      # Might as well automate the process.
      module XorDecode
        ALL_BYTES = (0..255).to_a
        KEY =
          [
            0x6c, 0x24, 0x84, 0x8e, 0x42, 0x19, 0xa8, 0xe1, 0xc5, 0xdb, 0x57, 0x65, 0xb9, 0xc6, 0x14, 0x9e,
            0xa5, 0x19, 0x35, 0x96, 0x3b, 0x39, 0x7f, 0xa5, 0x65, 0xd1, 0xfe, 0x01, 0x85, 0x7d, 0xd9, 0x4c
          ]

        def self.call(bytes)
          bytes.zip(KEY.cycle).map { |cipher_byte, key_byte| cipher_byte ^ key_byte }
        end
      end

      inside Two

      transform Ascii85::Decode
      transform XorDecode
    end
  end
end
