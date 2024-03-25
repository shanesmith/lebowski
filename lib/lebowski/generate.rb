require 'time'
require 'faraday'

module Lebowski
  class Generate
    GithubHost = "https://shanesmith.github.io/lebowski/"
    LocalHost = "http://localhost:8080/"
    Host = ENV["CI"] ? GithubHost : LocalHost

    WatchlistPath = "data/watchlist.json"
    OldWatchlistPath = "data/old-watchlist.json"
    UpdatesWatchlistPath = "data/updates-watchlist.json"
    ProviderlistPath = "data/providerlist.json"

    class << self
      def run
        unless old_watchlist.value.empty?
          updates_watchlist.prepend({
            "time" => Time.now.to_s,
            "updates" => old_watchlist.diff(watchlist).value,
          })
        end

        File.write(site_path(WatchlistPath), watchlist.to_json(pretty: true))
        File.write(site_path(ProviderlistPath), providerlist.to_json(pretty: true))
        File.write(site_path(OldWatchlistPath), old_watchlist.to_json(pretty: true))
        File.write(site_path(UpdatesWatchlistPath), JSON.pretty_generate(updates_watchlist))
      end

      def watchlist
        @watchlist ||= Lebowski::Watchlist.fetch(with_providers: true)
      end

      def providerlist
        @providerlist ||= Lebowski::Providerlist.new(watchlist)
      end

      def updates_watchlist
        @updates_watchlist ||= fetch(UpdatesWatchlistPath, default: [])
      end

      def old_watchlist
        @old_watchlist ||= Lebowski::Watchlist.new(fetch(WatchlistPath, default: []))
      end

      def fetch(path, default: nil)
        conn.get(path).body
      rescue Faraday::Error
        default
      end

      def site_path(path)
        "site/#{path}"
      end

      private

      def conn
        @conn ||= Faraday.new(Host) do |conn|
          conn.response :json
          conn.response :raise_error
        end
      end
    end
  end
end
