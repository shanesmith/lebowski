module Lebowski
  class Providerlist
    ADS_ALLOW = [
      "CBC Gem",
    ]

    SUBSCRIBED = [
      "Netflix",
      "Hollywood Suite Amazon Channel",
    ]

    GROUP = {
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

    @providerlist = nil

    def initialize(watchlist)
      @providerlist = process_watchlist(watchlist)
    end

    def value
      @providerlist
    end

    def to_json(pretty: false)
      if pretty
        JSON.pretty_generate(@providerlist)
      else
        @providerlist.to_json
      end
    end

    private

    def process_watchlist(watchlist)
      other_result = {
        "rent" => [],
        "buy" => [],
        "unavailable" => [],
      }

      result = watchlist.value.each_with_object({}) do |movie, providers|
        list = []

        list += (movie.dig("providers", "flatrate") || [])
          .each { |p| p["provider_name"].strip! }

        list += (movie.dig("providers", "ads") || [])
          .each { |p| p["provider_name"].strip! }
          .select { |p| ADS_ALLOW.include?(p["provider_name"]) }

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

      GROUP.each do |name,members|
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
          name = provider.delete_prefix('*')
          group = provider.start_with?("*") ? GROUP[provider[1..]] : nil
          {
            "provider" => name,
            "group" => group,
            "movies" => movies.sort_by { |m| m["other_providers"].size },
            "subscribed" => [name, *group].any? { |p| SUBSCRIBED.include?(p) }
          }
        end
        .sort_by do |elem|
          # unique movie count
          score = elem["movies"].filter { |m| m["other_providers"].empty? }.size
          score += 1000 if elem["subscribed"]
          score
        end
        .reverse

      {
        **other_result,
        "stream" => result,
      }
    end
  end
end
