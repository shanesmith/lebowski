require "thor"

class Error < Thor::Error; end

# TODO
#  - Sort movies by cross availability
# .- Take not of subscribed providers

module Lebowski
  class Cli < Thor
    Subscribed = [
      "Netflix",
      "Amazon Prime Video"
    ]

    Ignore = [
      "Netflix basic with Ads",
      "Hoopla"
    ]

    desc 'login', 'Login with Google'
    def login
      puts "LOGIN!"
    end

    desc 'user', 'Retrieve user data'
    def user
      puts "USER!"
    end

    desc 'wishlist', 'Show wishlist'
    def wishlist
      puts Lebowski::Trakt.wishlist.to_json
    end

    desc 'tmdb', 'TMDB'
    def tmdb
      wl = Lebowski::Trakt.wishlist

      # TODO parrallelize
      wl.each_with_index do |movie,index|
        STDERR.print "#{index},"
        STDERR.flush

        id = movie.dig('movie', 'ids', 'tmdb')
        if id.nil?
          STDERR.puts "Movie '#{movie['movie']['title']}' has no TMDB ID"
          next
        end

        movie["providers"] = Lebowski::TMDB.providers(id)
      end

      result = wl.each_with_object({}) do |movie, providers|
        list = movie.dig("providers", "flatrate")

        next if list.nil?

        list.reject! { |p| Ignore.include?(p["provider_name"]) }

        list.each do |p|
          name = p["provider_name"]

          providers[name] = [] unless providers.key?(name)

          providers[name] << {
            **movie["movie"],
            "link" => movie["providers"]["link"],
            "weight" => list.length,
          }
        end
      end

      result.each do |_, movies|
        movies.sort_by! { |m| m["weight"] }
      end

      puts result.to_json
    end
  end
end
