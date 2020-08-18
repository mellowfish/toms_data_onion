module Onion
  module Layers
    class Four < Base
      include Singleton

      inside Three

      module ByteBucket
        def byte_range(range)
          range.map { |index| bytes[index] << (8 * (range.end - index)) }.sum
        end
      end

      module BinaryMath
        def ones_complement_add(*numbers)
          numbers.reduce(0) do |sum, n|
            sum = sum + n
            if sum >= 2**16
              (sum - 2**16) + 1
            else
              sum
            end
          end ^ 0b1111111111111111
        end
      end

      class InternetPacket
        class Header
          include ByteBucket
          include BinaryMath

          def self.parse(bytes)
            new(bytes.shift(new(bytes[0..4]).internet_header_length))
          end

          attr_reader :bytes

          def initialize(bytes)
            @bytes = bytes
          end

          def version
            (bytes[0] & 0b11110000) >> 4
          end

          def internet_header_length
            (bytes[0] & 0b00001111) * 4
          end

          def type_of_service
            bytes[1]
          end

          def total_length
            byte_range(2..3)
          end

          def identification
            byte_range(4..5)
          end

          def flags
            (byte[6] & 0b11100000) >> 5
          end

          def fragment_offset
            ((bytes[6] & 0b00011111) << 13) + bytes[7]
          end

          def time_to_live
            bytes[8]
          end

          def protocol
            bytes[9]
          end

          def header_checksum
            byte_range(10..11)
          end

          def source_bytes
            bytes[12..15]
          end

          def source_address
            source_bytes.join(".")
          end

          def destination_bytes
            bytes[16..19]
          end

          def destination_address
            destination_bytes.join(".")
          end

          # Note: didn't implement options for now

          # End of standard fields

          def data_length
            total_length - internet_header_length
          end

          def data_class # not generic...
            UdpPacket
          end

          def checksum_valid?
            words_to_add = [
              byte_range(0..1), byte_range(2..3),
              byte_range(4..5), byte_range(6..7),
              byte_range(8..9), 0,
              byte_range(12..13), byte_range(14..15),
              byte_range(16..17), byte_range(18..19)
            ]

            if bytes.length > 20
              ((bytes.length - 20) / 2).times do |index|
                words_to_add << byte_range((20 + index)..(20 + index + 1))
              end
            end

            ones_complement_add(*words_to_add) == header_checksum
          end
        end

        def self.parse(bytes)
          header = Header.parse(bytes)
          new(
            header: header,
            data: header.data_class.parse(bytes.shift(header.data_length)),
          )
        end

        attr_reader :header, :data

        def initialize(header:, data:)
          @header = header
          @data = data
        end

        def valid?
          return false if header.source_address != "10.1.1.10"
          return false if header.destination_address != "10.1.1.200"
          return false if data.header.destination_port != 42069
          return false unless header.checksum_valid?
          return false unless data.checksum_valid?(self)

          # TODO checksums
          true
        end
      end

      class UdpPacket
        include BinaryMath

        class Header
          include ByteBucket

          attr_reader :bytes

          def initialize(bytes)
            @bytes = bytes
          end

          def source_port_bytes
            bytes[0..1]
          end

          def source_port
            byte_range(0..1)
          end

          def destination_port_bytes
            bytes[2..3]
          end

          def destination_port
            byte_range(2..3)
          end

          def length_bytes
            bytes[4..5]
          end

          def length
            byte_range(4..5)
          end

          def checksum
            byte_range(6..7)
          end

          # End of standard fields

          def data_length
            length - 8
          end

          def bytes_for_checksum
            bytes[0..5] + [0, 0]
          end
        end

        def self.parse(bytes)
          header = Header.new(bytes.shift(8))
          new(
            header: header,
            data: bytes.shift(header.data_length)
          )
        end

        attr_reader :header, :data

        def initialize(header:, data:)
          @header = header
          @data = data
        end

        def checksum_valid?(internet_packet)
          bytes_to_checksum = ipv4_psuedo_header(internet_packet.header) + header.bytes_for_checksum + data
          words_to_checksum = bytes_to_checksum.each_slice(2).map { |high_byte, low_byte| (high_byte << 8) + (low_byte || 0) }

          ones_complement_add(*words_to_checksum) == header.checksum
        end

        def ipv4_psuedo_header(real_ip_header)
          real_ip_header.source_bytes +
            real_ip_header.destination_bytes +
            [0, 17] + header.length_bytes
        end
      end

      module ParseInternetPackets
        def self.call(bytes)
          remaining_bytes = bytes
          packets = []
          while remaining_bytes.present?
            packets << InternetPacket.parse(remaining_bytes)
          end
          packets
        end
      end

      module DiscardBadPackets
        def self.call(packets)
          packets.select(&:valid?)
        end
      end

      module ReadBytesFromPackets
        def self.call(packets)
          packets.map(&:data).map(&:data).flatten
        end
      end

      transform Ascii85::Decode
      transform ParseInternetPackets
      transform DiscardBadPackets
      transform ReadBytesFromPackets
    end
  end
end
