module Onion
  module Layers
    class Five < Base
      include Singleton

      inside Four

      transform Ascii85::Decode
    end
  end
end
