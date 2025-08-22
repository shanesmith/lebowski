module Lebowski
  class Watchlist
    IGNORE_PROVIDERS = [
      "Netflix basic with Ads",
      "Netflix Standard with Ads",
      "Hoopla",
      "Club Illico",
      "iciTouTV",
      "Amazon Prime Video with Ads",
      "Paramount Plus Basic with Ads",
    ]

    @watchlist = nil

    class << self
      def fetch(with_providers: false)
        watchlist = Watchlist.new(Lebowski::Trakt.watchlist)
        watchlist.fetch_providers if with_providers
        watchlist
      end
    end

    def initialize(watchlist)
      @watchlist = watchlist
    end

    def fetch_providers
      @watchlist.each_with_index do |movie, index|
        id = movie.dig('movie', 'ids', 'tmdb')

        STDERR.puts "#{index} - #{movie['movie']['title']} (#{id})"

        if id.nil?
          STDERR.puts "Movie '#{movie['movie']['title']}' has no TMDB ID"
          movie["providers"] = []
          next
        end

        movie["providers"] = Lebowski::TMDB.providers(id)

        flatrate = movie.dig("providers", "flatrate")
        unless flatrate.nil?
          flatrate.reject! { |p| IGNORE_PROVIDERS.include?(p["provider_name"])}
          movie["providers"].delete("flatrate") if flatrate.empty?
        end
      end
    end

    def find_movie(id)
      @watchlist.find { |movie| movie["id"] == id }
    end

    def diff(other_list)
      diff_list = []

      is_unavailable = ->(providers) { providers.nil? || ['flatrate', 'rent', 'buy'].none? { |type| providers.key?(type) }  }
      provider_difference = ->(from, to) { from.reject { |f| to.find { |t| t['provider_name'] == f['provider_name'] } } }

      @watchlist.each do |movie|
        other_movie = other_list.find_movie(movie['id'])

        if other_movie.nil?
          diff_movie = Lebowski::Utils.deep_clone(movie)
          diff_movie['diff'] = [{ op: 'remove', type: 'movie' }]
          diff_list << diff_movie
          next
        end

        diff_movie = Lebowski::Utils.deep_clone(other_movie)
        diff_movie['diff'] = []

        providers = movie["providers"]
        other_providers = other_movie["providers"]

        if is_unavailable.call(providers)
          if is_unavailable.call(other_providers)
            next
          end

          diff_movie['diff'] << { op: 'remove', type: 'unavailable' }

          if other_providers['flatrate']
            diff_movie['diff'] << { op: 'add', type: 'providers', providers: other_providers['flatrate'] }
          elsif other_providers['rent']
            diff_movie['diff'] << { op: 'add', type: 'rent' }
          elsif other_providers['buy']
            diff_movie['diff'] << { op: 'add', type: 'buy' }
          end

        elsif providers['flatrate']
          if other_providers.nil?
            diff_movie['diff'] << { op: 'remove', type: 'providers', providers: providers['flatrate'] }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          elsif other_providers['flatrate']
            added = provider_difference.call(other_providers['flatrate'], providers['flatrate'])
            removed = provider_difference.call(providers['flatrate'], other_providers['flatrate'])

            next if added.empty? && removed.empty?

            diff_movie['diff'] << { op: 'add', type: 'providers', providers: added } unless added.empty?
            diff_movie['diff'] << { op: 'remove', type: 'providers', providers: removed } unless removed.empty?
          elsif other_providers['rent']
            diff_movie['diff'] << { op: 'remove', type: 'providers', providers: providers['flatrate'] }
            diff_movie['diff'] << { op: 'add', type: 'rent' }
          elsif other_providers['buy']
            diff_movie['diff'] << { op: 'remove', type: 'providers', providers: providers['flatrate'] }
            diff_movie['diff'] << { op: 'add', type: 'buy' }
          else
            diff_movie['diff'] << { op: 'remove', type: 'providers', providers: providers['flatrate'] }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          end

        elsif providers['rent']
          if other_providers.nil?
            diff_movie['diff'] << { op: 'remove', type: 'rent' }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          elsif other_providers['flatrate']
            diff_movie['diff'] << { op: 'remove', type: 'rent' }
            diff_movie['diff'] << { op: 'add', type: 'providers', providers: other_providers['flatrate'] }
          elsif other_providers['rent']
            next
          elsif other_providers['buy']
            diff_movie['diff'] << { op: 'remove', type: 'rent' }
            diff_movie['diff'] << { op: 'add', type: 'buy' }
          else
            diff_movie['diff'] << { op: 'remove', type: 'rent' }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          end

        elsif providers['buy']
          if other_providers.nil?
            diff_movie['diff'] << { op: 'remove', type: 'buy' }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          elsif other_providers['flatrate']
            diff_movie['diff'] << { op: 'remove', type: 'buy' }
            diff_movie['diff'] << { op: 'add', type: 'providers', providers: other_providers['flatrate'] }
          elsif other_providers['rent']
            diff_movie['diff'] << { op: 'remove', type: 'buy' }
            diff_movie['diff'] << { op: 'add', type: 'rent' }
          elsif other_providers['buy']
            next
          else
            diff_movie['diff'] << { op: 'remove', type: 'rent' }
            diff_movie['diff'] << { op: 'add', type: 'unavailable' }
          end

        else
          if other_providers.nil?
            next
          elsif other_providers['flatrate']
            diff_movie['diff'] << { op: 'remove', type: 'unavailable' }
            diff_movie['diff'] << { op: 'add', type: 'providers', providers: other_providers['flatrate'] }
          elsif other_providers['rent']
            diff_movie['diff'] << { op: 'remove', type: 'unavailable' }
            diff_movie['diff'] << { op: 'add', type: 'rent' }
          elsif other_providers['buy']
            diff_movie['diff'] << { op: 'remove', type: 'unavailable' }
            diff_movie['diff'] << { op: 'add', type: 'buy' }
          else
            next
          end

        end

        diff_list << diff_movie
      end

      other_list.value.each do |other_movie|
        movie = find_movie(other_movie['id'])

        if movie.nil?
          diff_movie = Lebowski::Utils.deep_clone(other_movie)
          diff_movie['diff'] = [{ op: 'add', type: 'movie' }]
          diff_list << diff_movie
          next
        end
      end

      Lebowski::Diff.new(diff_list)
    end

    def value
      @watchlist
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(@watchlist)
      else
        @watchlist.to_json
      end
    end
  end
end
