module Onion
  module Layers
    class Zero < Base
      include Singleton

      inside Seed
      transform Ascii85::Decode

      def full_text_from_previous_layer
        Seed.instance.decoded_payload
      end
    end
  end
end
