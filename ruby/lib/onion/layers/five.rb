module Onion
  module Layers
    class Five < Base
      include Singleton

      inside Four

      class EncryptionContext
        attr_reader :key_encrypting_key, :key_initialization_vector, :wrapped_key
        attr_reader :initialization_vector, :ciphertext

        def initialize(bytes)
          @key_encrypting_key = Base::BytesToText.call(bytes.shift(32))
          @key_initialization_vector = Base::BytesToText.call(bytes.shift(8))
          @wrapped_key = Base::BytesToText.call(bytes.shift(40))
          @initialization_vector = Base::BytesToText.call(bytes.shift(16))
          @ciphertext = Base::BytesToText.call(bytes)
        end

        def key
          @key ||= AESKeyWrap.unwrap(wrapped_key, key_encrypting_key, key_initialization_vector)
        end

        def decipher
          @decipher ||= OpenSSL::Cipher.new("AES-256-CTR").tap { |c| c.decrypt }
        end

        def decrypt
          decipher.key = key
          decipher.iv = initialization_vector

          (decipher.update(ciphertext) + decipher.final).chars
        end
      end

      module ExtractEncryptionContext
        def self.call(bytes)
          EncryptionContext.new(bytes)
        end
      end

      module Decrypt
        def self.call(encryption_context)
          encryption_context.decrypt
        end
      end

      transform Ascii85::Decode
      transform ExtractEncryptionContext
      transform Decrypt
    end
  end
end
