require 'time'
require 'faraday'

module Lebowski
  class Generate
    GITHUB_HOST = "https://shanesmith.github.io/lebowski/"
    LOCAL_HOST = "http://localhost:8080/"
    Host = ENV["CI"] ? GITHUB_HOST : LOCAL_HOST

    WATCHLIST_PATH = "data/watchlist.json"
    OLD_WATCHLIST_PATH = "data/old-watchlist.json"
    UPDATES_WATCHLIST_PATH = "data/updates-watchlist.json"
    PROVIDERLIST_PATH = "data/providerlist.json"

    class << self
      def run
        unless old_watchlist.value.empty?
          new_updates = old_watchlist.diff(watchlist)

          unless new_updates.value.empty?
            updates_watchlist.prepend({
              "time" => Time.now.to_s,
              "updates" => new_updates.value,
            })
          end
        end

        File.write(site_path(WATCHLIST_PATH), watchlist.to_json(pretty: true))
        File.write(site_path(PROVIDERLIST_PATH), providerlist.to_json(pretty: true))
        File.write(site_path(OLD_WATCHLIST_PATH), old_watchlist.to_json(pretty: true))
        File.write(site_path(UPDATES_WATCHLIST_PATH), JSON.pretty_generate(updates_watchlist))
      end

      def watchlist
        @watchlist ||= Lebowski::Watchlist.fetch(with_providers: true, with_people: true)
      end

      def providerlist
        @providerlist ||= Lebowski::Providerlist.new(watchlist)
      end

      def updates_watchlist
        @updates_watchlist ||= fetch(UPDATES_WATCHLIST_PATH, default: [])
      end

      def old_watchlist
        @old_watchlist ||= Lebowski::Watchlist.new(fetch(WATCHLIST_PATH, default: []))
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
