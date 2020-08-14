module Onion
  module Layers
    class One < Base
      include Singleton

      module RotateBytesRight
        def self.call(data)
          data.map { |byte| (byte >> 1) | ((byte & 1) << 7) }
        end
      end

      module FlipEveryOtherBit
        def self.call(data)
          data.map { |byte| byte ^ 0b01010101 }
        end
      end

      inside Zero
      transform Ascii85::Decode
      transform FlipEveryOtherBit
      transform RotateBytesRight
    end
  end
end
