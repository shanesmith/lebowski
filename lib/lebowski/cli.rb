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

    desc 'diff', 'Diff!'
    def diff
      conn = Faraday.new(Host) do |conn|
        conn.response :json
        conn.response :raise_error
      end

      current_diff = conn.get("data/diff.json").body rescue []

      current_diff = current_diff.take_while { |d| Time.parse(d["time"]) > DiffCleanTime }

      old = if File.exist?("site/data/old-providerlist.json")
              JSON.load_file("site/data/old-providerlist.json")
            else
              conn.get("data/providerlist.json").body rescue nil
            end

      if old.nil?
        puts JSON.pretty_generate(current_diff)
        return
      end

      data = JSON.load_file("site/providerlist.json")
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
    # - Adding/Removing movie from watchlist
    # - Adding/Removing a whole provider isn't reflected
    #   - Remove all movies from a provider will remove the provider
    desc 'updates', "Updates"
    def updates
      conn = Faraday.new(Host) do |conn|
        conn.response :json
        conn.response :raise_error
      end
      current_updates = conn.get("data/updates.json").body rescue []

      current_updates = current_updates.take_while { |d| Time.parse(d["time"]) > UpdatesCleanTime }

      old = if File.exist?("site/data/old-providerlist.json")
              JSON.load_file("site/data/old-providerlist.json")
            else
              conn.get("data/providerlist.json").body rescue nil
            end

      if old.nil?
        puts JSON.pretty_generate(current_updates)
        return
      end

      data = JSON.load_file("site/data/providerlist.json")
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

    desc 'watchlist', 'Show watchlist'
    option :'with-providers', :type => :boolean
    option :pretty, :type => :boolean
    def watchlist
      puts Lebowski::Watchlist
        .fetch(with_providers: options[:'with-providers'])
        .to_json(pretty: options[:pretty])
    end

    desc 'providerlist', 'Provider List'
    option :pretty, :type => :boolean
    def providerlist
     watchlist = Lebowski::Watchlist.fetch(with_providers: true)

     puts Lebowski::Providerlist.new(watchlist)
        .to_json(pretty: options[:pretty])
    end
  end
end
