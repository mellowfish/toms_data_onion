require "active_support"
require "active_support/core_ext"

require "aes_key_wrap"
require "down"
require "fileutils"
require "pry"
require "openssl"

module Onion
  DATA_DIR = "./data"

  def self.data_path(relative_path)
    File.join(DATA_DIR, relative_path)
  end
end

require_relative "onion/ascii85"
require_relative "onion/reseed"
require_relative "onion/layers/base"
require_relative "onion/layers/seed"
require_relative "onion/layers/zero"
require_relative "onion/layers/one"
require_relative "onion/layers/two"
require_relative "onion/layers/three"
require_relative "onion/layers/four"
require_relative "onion/layers/five"
require_relative "onion/layers/six"
