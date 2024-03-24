module Lebowski
  class Diff
    def initialize(diff)
      @diff = diff
    end

    def value
      @diff
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(@diff)
      else
        @diff.to_json
      end
    end
  end
end
