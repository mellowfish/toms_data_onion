module Onion
  module Layers
    class Base
      PAYLOAD_BOUNDARY = "==[ Payload ]==============================================="

      module BytesToText
        def self.call(data)
          data.map(&:chr).join
        end
      end

      class << self
        def layer_name
          "layer_#{name.demodulize.underscore}"
        end

        def path
          Onion.data_path(layer_name)
        end

        def clear!
          FileUtils.rm(path) rescue nil
        end

        def inside(previous_layer = Base)
          @previous_layer = previous_layer
        end

        def previous_layer
          @previous_layer
        end

        def transforms
          @transforms ||= []
        end

        def all_transforms
          transforms + [BytesToText]
        end

        def transform(callable)
          transforms << callable
        end
      end

      delegate :path, :layer_name, :previous_layer, :all_transforms, to: :class

      def initialize
        ensure_text!
      end

      def ensure_text!
        exist? || write_text
      end

      def write_text
        unless full_text_from_previous_layer.include?(PAYLOAD_BOUNDARY)
          puts full_text_from_previous_layer
          raise "Decode failed!"
        end

        File.open(path, "w") do |file|
          file.write(full_text_from_previous_layer)
        end
      end

      def exist?
        FileUtils.mkdir_p(DATA_DIR)

        File.exist?(path)
      end

      def full_text
        @full_text ||= exist? ? full_text_from_disk : full_text_from_previous_layer
      end

      def full_text_from_disk
        File.read(path)
      end

      def full_text_from_previous_layer
        previous_layer.instance.decoded_payload
      end

      def text_parts(text = full_text)
        @text_parts ||= text.split(PAYLOAD_BOUNDARY)
      end

      def instructions
        @instructions ||= text_parts[0]
      end
      alias_method :to_s, :instructions

      def encoded_payload
        @encoded_payload ||= text_parts[1]
      end

      def decoded_payload
        all_transforms.reduce(encoded_payload) { |payload, transform| transform.call(payload) }
      end
    end
  end
end
