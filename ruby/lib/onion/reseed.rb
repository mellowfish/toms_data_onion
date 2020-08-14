module Onion
  class Reseed
    include Singleton

    def call
      puts "Deleting #{DATA_DIR}"
      FileUtils.rm_rf(DATA_DIR)

      Layers::Seed.instance
    end
  end
end
