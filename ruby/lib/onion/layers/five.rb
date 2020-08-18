module Onion
  module Layers
    class Five < Base
      include Singleton

      inside Four

      module ExtractEncryptionContext
        def self.call(bytes)
          [bytes]
        end
      end

      module Decrypt
        def self.call(encryption_context, bytes)
          [bytes]
        end
      end

      transform Ascii85::Decode
      transform ExtractEncryptionContext
      transform Decrypt
    end
  end
end
