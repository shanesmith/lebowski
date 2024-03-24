require "time"
require "thor"
require "hana"
require 'faraday'

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
    option :pretty, :type => :boolean
    def diff(from_path, to_path)
      from_watchlist = Lebowski::Watchlist.new(JSON.load_file(from_path))
      to_watchlist = Lebowski::Watchlist.new(JSON.load_file(to_path))

      puts from_watchlist.diff(to_watchlist)
        .to_json(pretty: options[:pretty])
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
