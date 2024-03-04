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
      "Club Illico",
      "iciTouTV",
    ]

    AdsAllow = [
      "CBC Gem",
    ]

    Group = {
      "Starz" => [
        "Crave Starz",
        "Starz Amazon Channel"
      ],
      "Paramount Plus" => [
        "Paramount Plus",
        "Paramount+ Amazon Channel",
        "Paramount Plus Apple TV Channel",
      ],
      "Hollywood Suite" => [
        "Hollywood Suite",
        "Hollywood Suite Amazon Channel",
      ],
      "IFC Films" => [
        "IFC Amazon Channel",
        "IFC Films Unlimited Apple TV Channel",
      ],
      "Sundance Now" => [
        "Sundance Now",
        "Sundance Now Apple TV Channel",
        "Sundance Now Amazon Channel",
      ],
      "Shudder" => [
        "Shudder",
        "Shudder Amazon Channel",
        "Shudder Apple TV Channel",
      ],
      "AMC+" => [
        "AMC+",
        "AMC+ Amazon Channel",
      ]
    }

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
        list = []

        list += (movie.dig("providers", "flatrate") || [])
          .each { |p| p["provider_name"].strip! }
          .reject { |p| Ignore.include?(p["provider_name"]) }

        list += (movie.dig("providers", "ads") || [])
          .each { |p| p["provider_name"].strip! }
          .select { |p| AdsAllow.include?(p["provider_name"]) }

        next if list.empty?

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

      Group.each do |name,members|
        name = "*#{name}"
        result[name] = []
        members.each do |m|
          other_members = members.dup.tap { |a| a.delete(m) }
          if result[m].nil?
            STDERR.puts "No such provider: #{m}"
            next
          end
          common_movies = result[m].select do |movie|
            other_members.difference(movie["other_providers"]).empty?
          end
          common_movies.each { |movie| movie["other_providers"] -= members }
          result[name] += common_movies
          result[m] -= common_movies
          result.delete(m) if result[m].empty?
        end
        result[name].uniq!
      end

      result = result
        .map do |provider, movies|
          {
            "provider" => provider,
            "group" => provider.start_with?("*") ? Group[provider[1..]] : nil,
            "movies" => movies.sort_by { |m| m["other_providers"].size },
          }
        end
        .sort_by { |elem| elem["movies"].filter { |m| m["other_providers"].empty? }.size }
        .reverse

      puts result.to_json
    end
  end
end
