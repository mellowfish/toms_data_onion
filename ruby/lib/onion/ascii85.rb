module Onion
  module Ascii85 # Note: https://en.wikipedia.org/wiki/Ascii85#Adobe_version
    START_TAG = "<~"
    END_TAG = "~>"

    module Encode
      class << self
        def call(plaintext)
          padding = (4 - plaintext.length % 4)
          padding.times do
            plaintext << 0
          end

          cipher_text =
            plaintext
              .each_slice(4)
              .map { |group| text_from_value(value_from_group(group)) }
              .join[0..(-1 - padding)]

          START_TAG + cipher_text + END_TAG
        end

      private

        def value_from_group(group)
          group.reverse.map.with_index { |char, index| char.ord * (256 ** index) }.sum
        end

        def text_from_value(value)
          return "z" if value.zero?

          original = value

          characters = []
          5.times do
            character_value = value % 85
            characters << (character_value + 33).chr
            value = (value - character_value) / 85
          end

          raise "Invalid value: #{original}" if value != 0
          characters.reverse.join
        end
      end
    end

    module Decode
      class << self
        def call(ciphertext)
          ciphertext = ciphertext.gsub(/\s/, '')
          raise "Invalid format: missing start tag '<~'" unless ciphertext[0..1] == "<~"
          raise "Invalid format: missing end tag '~>'" unless ciphertext[-2..-1] == "~>"
          ciphertext = ciphertext[2..-3]

          ciphertext = ciphertext.chars
          padding = (5 - ciphertext.length % 5) % 5
          padding.times do
            ciphertext << "u"
          end

          ciphertext
            .each_slice(5)
            .map { |group| text_from_value(value_from_group(group)) }
            .join[0..(-1 - padding)]
            .chars
            .map(&:ord)
        end

      private

        def value_from_group(group)
          if group.include?("z")
            return 0 if group[0] == "z" && group.compact.length == 1

            raise "Invalid format, stray z detected"
          end

          group.reverse.map.with_index { |char, index| (char.ord - 33) * (85 ** index) }.sum
        end

        def text_from_value(value)
          original = value
          characters = []
          4.times do
            char_value = value % 256
            characters << char_value.chr
            value = (value - char_value) / 256
          end
          raise "Invalid value: #{original}" if value != 0
          characters.reverse.join
        end
      end
    end

    class << self
      def encode(plaintext)
        Encode.call(plaintext)
      end

      def decode(ciphertext)
        Decode.call(ciphertext)
      end
    end
  end
end
