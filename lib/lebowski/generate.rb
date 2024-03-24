require 'time'
require 'faraday'

module Lebowski
  class Generate
    Host = ENV["CI"] ? "https://shanesmith.github.io/lebowski/" : "http://localhost:8080/"

    class << self
      def run
        unless old_watchlist.value.empty?
          updates_watchlist.prepend({
            "time" => Time.now.to_s,
            "updates" => old_watchlist.diff(watchlist).value,
          })
        end

        File.write("site/data/watchlist.json", watchlist.to_json(pretty: true))
        File.write("site/data/providerlist.json", providerlist.to_json(pretty: true))
        File.write("site/data/old-watchlist.json", old_watchlist.to_json(pretty: true))
        File.write("site/data/updates-watchlist.json", JSON.pretty_generate(updates_watchlist))
      end

      private

      def conn
        @conn ||= Faraday.new(Host) do |conn|
          conn.response :json
          conn.response :raise_error
        end
      end

      def watchlist
        @watchlist ||= Lebowski::Watchlist.fetch(with_providers: true)
      end

      def providerlist
        @providerlist ||= Lebowski::Providerlist.new(watchlist)
      end

      def updates_watchlist
        @updates_watchlist ||= begin
          conn.get("data/updates-watchlist.json").body
        rescue Faraday::Error
          []
        end
      end

      def old_watchlist
        @old_watchlist ||= begin
          data = begin
            conn.get("data/watchlist.json").body
          rescue Faraday::Error
            []
          end

          Lebowski::Watchlist.new(data)
        end
      end
    end
  end
end
