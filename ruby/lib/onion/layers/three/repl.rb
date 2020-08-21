module Onion
  module Layers
    class Three < Base
      class Repl
        WHITE_BOX = "\u25A1"

        attr_reader :bytes, :key, :direction

        delegate :decrypt, to: :class

        def initialize(bytes)
          @bytes = bytes
          @key = Array.new(32, 0)
          @direction = :reverse
        end

        def reveal_key
          loop do
            render
            prompt
          end
        end

        def render
          puts key_index_string
          puts divider
          puts key_string
          puts divider
          data_rows.each do |(row, index)|
            puts printable_row(row, index)
          end
          puts divider
          puts key_string
          puts divider
          puts key_index_string
        end

      private

        def key_string
          "KEY => | " + key.map { |byte| "%02x" % byte }.join(" | ") + " |"
        end

        def key_index_string
          "INDEX  | " + (0..31).map { |n| "%2d" % n }.join(" | ") + " |"
        end

        def divider
          "       |--" + ("--+--" * 31) + "--|"
        end

        def data
          decrypt(bytes: bytes, key: key)
        end

        def data_rows
          data.each_slice(32).each_with_index.yield_self { |rows| direction == :reverse ? rows.to_a.reverse : rows }
        end

        def printable_row(row, index)
          ("[%4d] |  " % index) + row.map.with_index { |byte, byte_index| printable_character(byte, byte_index) }.join(" |  ") + " |"
        end

        def printable_character(byte, index)
          return WHITE_BOX if byte < 32 || byte > 126

          character = byte.chr

          return WHITE_BOX if key[index].zero? && "\n\r\t ".include?(character)

          character
        end

        def prompt
          display_prompt

          execute(STDIN.gets)
        end

        def execute(statement)
          command, expression = statement.split(" ", 2)

          case command.downcase
          when "help"
            display_help
          when "set"
            set_key_value(expression)
          when "guess"
            guess_plain_text(expression)
          when "q", "quit", "exit"
            exit
          else
            puts "invalid command!"
            exit
          end
        end

        def display_prompt
          puts
          puts "Enter command (exit, set, help...)"
          print "$: "
        end

        def display_help
          help_text =
            <<~TXT
              help
              set <column>=<hex_key_value>
              # set 12=a1
              guess <column>{,<row=0>}=<decrypted_character>
              # guess 12,2=
              exit
          TXT

          puts help_text

          prompt
        end

        def set_key_value(expression)
          args = expression.split("=", 2)
          raise "set <column>=<hex_key_value>" unless args.length == 2
          column = args[0].to_i
          raise "column must be in 0..31" unless (0..31).cover?(column)
          raise "invalid hex key value: #{args[1]}" unless args[1].match?(/^[0-9a-f]{2,}$/i)
          hex_key_value = args[1].to_i(16)
          key[column] = hex_key_value
        end

        def guess_plain_text(expression)
          args = expression.split("=", 2)
          raise "[1] guess <column>{,<row=0>}=<decrypted_character>" unless args.length == 2
          position_args = args[0].split(",", 2)
          raise "[2] guess <column>{,<row=0>}=<decrypted_character>" unless [1, 2].include?(position_args.length)
          column = position_args[0].to_i
          raise "column must be in 0..31" unless (0..31).cover?(column)
          row = position_args[1]&.to_i || 0
          raise "[3] guess <column>{,<row=0>}=<decrypted_character>" unless args[1].length == 2
          character = args[1][0]
          key[column] = character.ord ^ bytes[row * 32 + column]
        end
      end
    end
  end
end
