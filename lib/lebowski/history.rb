module Lebowski
  class History
    @history = nil

    class << self
      def fetch
        History.new(Lebowski::Trakt.history)
      end
    end

    def initialize(history)
      @history = history
    end

    def value
      @history
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(value)
      else
        value.to_json
      end
    end
  end
end