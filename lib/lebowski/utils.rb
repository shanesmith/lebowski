module Lebowski
  module Utils
    def self.deep_clone(obj)
      Marshal.load(Marshal.dump(obj))
    end
  end
end
