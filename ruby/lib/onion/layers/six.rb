module Onion
  module Layers
    class Six < Base
      include Singleton

      inside Five

      transform Ascii85
    end
  end
end
