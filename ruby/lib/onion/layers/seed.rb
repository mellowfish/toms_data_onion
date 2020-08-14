module Onion
  module Layers
    class Seed < Base
      include Singleton

      URL = "https://www.tomdalling.com/toms-data-onion/"

      def self.path
        Onion.data_path("seed.html")
      end

      def full_text_from_previous_layer
        Downloader.call(path)

        full_text_from_disk
      end

      def decoded_payload(html = pre_tag)
        CGI.unescapeHTML(html.tr(" ", " "))
      end

    private

      def pre_tag(html = full_text_from_disk)
        @pre_tag ||= html[%r{(?<=<pre>).+(?=</pre>)}m]
      end

      module Downloader
        def self.call(path)
          puts "Downloading from #{URL} to #{path}"
          Down.download(URL, destination: path)
        end
      end
    end
  end
end
