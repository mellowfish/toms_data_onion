module Onion
  module Layers
    class Four < Base
      include Singleton

      inside Three

      class Packet
        def valid?
          true
        end
      end

      module ParsePackets
        def self.call(bytes)
          raise "parse failed"
          [] # packets
        end
      end

      module DiscardBadPackets
        def self.call(packets)
          raise "packet filter failed"
          packets.select(&:valid?)
        end
      end

      module ReadBytesFromPackets
        def self.call(packets)
          raise "packet data failed"
          [] # bytes
        end
      end

      transform Ascii85::Decode
      transform ParsePackets
      transform DiscardBadPackets
      transform ReadBytesFromPackets
    end
  end
end
