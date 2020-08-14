module Onion
  module Layers
    class Three < Base
      include Singleton

      module XorDecode
        def self.call(bytes)
          # TODO
        end
      end

      inside Two

      transform Ascii85::Decode
      transform XorDecode
    end
  end
end
