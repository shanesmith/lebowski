require "time"
require "thor"
require "hana"
require 'faraday'
require "json-diff"

class Error < Thor::Error; end

# TODO
# - Login
# - Update summary
# - Parralelize TMDB calls
# - Check US availability?

module Lebowski
  class Cli < Thor
    DiffCleanTime = Time.parse("2024-03-10 22:22:50 -0400")
    UpdatesCleanTime = Time.parse("2020-08-25 00:00:00 -0400")

    Host = ENV["CI"] ? "https://shanesmith.github.io/lebowski/" : "http://localhost:8080/"

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
      ],
      "Super Channel" => [
        "Super Channel Amazon Channel",
        "fuboTV",
      ],
      "Crunchyroll" => [
        "Crunchyroll",
        "Crunchyroll Amazon Channel",
      ]
    }

    desc 'diff', 'Diff!'
    def diff
      conn = Faraday.new(Host) do |conn|
        conn.response :json
        conn.response :raise_error
      end

      current_diff = conn.get("diff.json").body rescue []

      current_diff = current_diff.take_while { |d| Time.parse(d["time"]) > DiffCleanTime }

      old = if File.exist?("site/old.json")
              JSON.load_file("site/old.json")
            else
              conn.get("data.json").body rescue nil
            end

      if old.nil?
        puts JSON.pretty_generate(current_diff)
        return
      end

      data = JSON.load_file("site/data.json")
      diff = JsonDiff.diff(old, data, include_was: true, origial_indices: true, moves: false)

      if diff.empty?
        puts JSON.pretty_generate(current_diff)
        return
      end

      diff.map! do |d|
        op = d["op"]
        path = Hana::Pointer.parse(d['path'])

        target = (op == "remove") ? old : data

        movie_index = (path[0] == "stream") ? 4 : 2

        if path.size > movie_index
          d["movie"] = Hana::Pointer.eval(path.take(movie_index), target)
        end

        if path[0] == "stream" && path.size > 2
          d["provider"] = Hana::Pointer.eval(path.take(2).append("provider"), target)
        end

        d
      end

      current_diff.unshift({
        "time" => Time.now.to_s,
        "diff" => diff,
      })

      puts JSON.pretty_generate(current_diff)
    end

    # TODO
    # - Adding/Removing movie from wishlist
    # - Adding/Removing a whole provider isn't reflected
    #   - Remove all movies from a provider will remove the provider
    desc 'updates', "Updates"
    def updates
      conn = Faraday.new(Host) do |conn|
        conn.response :json
        conn.response :raise_error
      end
      current_updates = conn.get("updates.json").body rescue []

      current_updates = current_updates.take_while { |d| Time.parse(d["time"]) > UpdatesCleanTime }

      old = if File.exist?("site/old.json")
              JSON.load_file("site/old.json")
            else
              conn.get("data.json").body rescue nil
            end

      if old.nil?
        puts JSON.pretty_generate(current_updates)
        return
      end

      data = JSON.load_file("site/data.json")
      diff = JsonDiff.diff(old, data, include_was: true, origial_indices: true, moves: false)

      if diff.empty?
        puts JSON.pretty_generate(current_updates)
        return
      end

      updates = diff.each_with_object({}) do |d, updates|
        op = d["op"]
        path = Hana::Pointer.parse(d['path'])
        target = (op == "remove") ? old : data
        movie_index = (path[0] == "stream") ? 4 : 2

        next if path.size != movie_index

        movie = Hana::Pointer.eval(path, target)
        id = movie["ids"]["tmdb"]

        updates[id] ||= {
          "tmdb_id" => id,
          "title" => movie["title"],
          "year" => movie["year"],
          "link" => movie["link"],
          "remove" => [],
          "add" => [],
          "providers" => data["stream"]
            .select { |p| p["movies"].any? { |m| m["ids"]["tmdb"] == id } }
            .map { |p| p["provider"] },

        }

        updates[id][op] << if path[0] == "stream"
                             Hana::Pointer.eval(path.take(2).append("provider"), target)
                           else
                             path[0].capitalize
                           end
      end

      if updates.empty?
        puts JSON.pretty_generate(current_updates)
        return
      end

      current_updates.unshift({
        "time" => Time.now.to_s,
        "updates" => updates,
      })

      puts JSON.pretty_generate(current_updates)
    end

    desc 'wishlist', 'Show wishlist'
    def wishlist
      puts Lebowski::Trakt.wishlist.to_json
    end

    desc 'providers', 'Providers'
    def providers
      wl = Lebowski::Trakt.wishlist

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

      other_result = {
        "rent" => [],
        "buy" => [],
        "unavailable" => [],
      }

      result = wl.each_with_object({}) do |movie, providers|
        list = []

        list += (movie.dig("providers", "flatrate") || [])
          .each { |p| p["provider_name"].strip! }
          .reject { |p| Ignore.include?(p["provider_name"]) }

        list += (movie.dig("providers", "ads") || [])
          .each { |p| p["provider_name"].strip! }
          .select { |p| AdsAllow.include?(p["provider_name"]) }

        item = {
          **movie["movie"],
          "link" => "https://www.themoviedb.org/movie/#{movie.dig("movie", "ids", "tmdb")}/watch?locale=CA",
        }

        if list.empty?
          if movie.dig("providers", "rent")
            other_result["rent"] << item
          elsif movie.dig("providers", "buy")
            other_result["buy"] << item
          else
            other_result["unavailable"] << item
          end
        end

        list.each do |p|
          name = p["provider_name"]

          providers[name] ||= []

          providers[name] << {
            **item,
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
            "provider" => provider.delete_prefix('*'),
            "group" => provider.start_with?("*") ? Group[provider[1..]] : nil,
            "movies" => movies.sort_by { |m| m["other_providers"].size },
          }
        end
        .sort_by { |elem| elem["movies"].filter { |m| m["other_providers"].empty? }.size }
        .reverse

      json = {
        **other_result,
        "stream" => result,
      }.to_json

      puts json
    end
  end
end
