require "thor"

class Error < Thor::Error; end

# TODO
# - Login
# - Combine channels (Starz, Paramount, etc..)
# - Update summary

module Lebowski
  class Cli < Thor
    Subscribed = [
      "Netflix",
      "Amazon Prime Video"
    ]

    Ignore = [
      "Netflix basic with Ads",
      "Hoopla",
      "Club Illico"
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

      result = wl.each_with_object({}) do |movie, providers|
        list = movie
          .dig("providers", "flatrate")
          &.reject { |p| Ignore.include?(p["provider_name"]) }

        next if list.nil? || list.empty?

        list.each do |p|
          name = p["provider_name"]

          providers[name] = [] unless providers.key?(name)

          providers[name] << {
            **movie["movie"],
            "link" => movie["providers"]["link"],
            "other_providers" => list.map { |p| p["provider_name"] }.reject { |p| p == name },
          }
        end
      end

      result = result
        .map do |provider, movies|
          {
            "provider" => provider,
            "movies" => movies.sort_by { |m| m["other_providers"].size },
          }
        end
        .sort_by { |elem| elem["movies"].filter { |m| m["other_providers"].empty? }.size }
        .reverse

      puts result.to_json
    end
  end
end
