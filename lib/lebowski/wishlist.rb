module Lebowski
  class Wishlist
    @wishlist = nil

    class << self
      def fetch(with_providers: false)
        wishlist = Wishlist.new(Lebowski::Trakt.wishlist)
        wishlist.fetch_providers if with_providers
        wishlist
      end
    end

    def initialize(wishlist)
      @wishlist = wishlist
    end

    def fetch_providers
      @wishlist.each_with_index do |movie, index|
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
      @wishlist
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(@wishlist)
      else
        @wishlist.to_json
      end
    end
  end
end
