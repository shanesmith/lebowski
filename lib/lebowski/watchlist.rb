module Lebowski
  class Watchlist
    @watchlist = nil

    class << self
      def fetch(with_providers: false)
        watchlist = Watchlist.new(Lebowski::Trakt.watchlist)
        watchlist.fetch_providers if with_providers
        watchlist
      end
    end

    def initialize(watchlist)
      @watchlist = watchlist
    end

    def fetch_providers
      @watchlist.each_with_index do |movie, index|
        id = movie.dig('movie', 'ids', 'tmdb')

        STDERR.puts "#{index} - #{movie['movie']['title']} (#{id})"

        if id.nil?
          STDERR.puts "Movie '#{movie['movie']['title']}' has no TMDB ID"
          movie["providers"] = []
          next
        end

        movie["providers"] = Lebowski::TMDB.providers(id)
        STDERR.puts (movie.dig("providers", "flatrate") || []).map { |p| p["provider_name"] }.join(" / ")
      end
    end

    def value
      @watchlist
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(@watchlist)
      else
        @watchlist.to_json
      end
    end
  end
end
