require 'faraday'

# https://www.hansschnedlitz.com/2021/02/26/cli-oauth-in-ruby.html

module Lebowski
  class Trakt
    CLIENT_ID = ENV['TRAKT_CLIENT_ID']
    CLIENT_SECRET = ENV['TRAKT_CLIENT_SECRET']
    ACCESS_TOKEN = ENV['TRAKT_ACCESS_TOKEN']

    class <<self

      # [{"rank"=>1,
      #   "id"=>985612439,
      #   "listed_at"=>"2024-02-24T14:07:17.000Z",
      #   "notes"=>nil,
      #   "type"=>"movie",
      #   "movie"=>
      #      {"title"=>"Hundreds of Beavers",
      #       "year"=>2024,
      #       "ids"=>{
      #         "trakt"=>820070,
      #         "slug"=>"hundreds-of-beavers-2024",
      #         "imdb"=>"tt12818328",
      #         "tmdb"=>1019939}}},
      def watchlist
        conn.get("/users/me/watchlist/movies/added", { extended: "full", limit: "1000" }).body
      end

      def people(id)
        conn.get("/movies/#{id}/people").body
      end

      # [{
      #   "last_updated_at": "2025-12-04T04:23:00.000Z",
      #   "last_watched_at": "2025-12-04T04:23:02.000Z",
      #   "movie": {
      #     "ids": {
      #       "imdb": "tt0112817",
      #       "plex": {
      #         "guid": "5d7768284de0ee001fcc8f50",
      #         "slug": "dead-man"
      #       },
      #       "slug": "dead-man-1995",
      #       "tmdb": 922,
      #       "trakt": 764
      #     },
      #     "year": 1995,
      #     "title": "Dead Man",
      #     "votes": 2042,
      #     "colors": {
      #       "poster": ["#DADADA", "#272525"]
      #     },
      #     "genres": ["drama", "fantasy", "western"],
      #     "images": {
      #       "logo": ["media.trakt.tv/images/movies/000/000/764/logos/medium/1da33ecf9f.png.webp"],
      #       "thumb": ["media.trakt.tv/images/movies/000/000/764/thumbs/medium/c3f49f6b33.jpg.webp"],
      #       "banner": ["media.trakt.tv/images/movies/000/000/764/banners/medium/87c5877261.jpg.webp"],
      #       "fanart": ["media.trakt.tv/images/movies/000/000/764/fanarts/medium/c793b5d232.jpg.webp"],
      #       "poster": ["media.trakt.tv/images/movies/000/000/764/posters/medium/b11d5fd641.jpg.webp"],
      #       "clearart": []
      #     },
      #     "rating": 7.2575907707214355,
      #     "status": "released",
      #     "country": "us",
      #     "runtime": 121,
      #     "tagline": "It is preferable not to travel with a dead man.",
      #     "trailer": "https://youtube.com/watch?v=FEHMWguT--U",
      #     "homepage": null,
      #     "language": "en",
      #     "overview": "On the run after committing murder, an accountant encounters a strange Native American man who prepares him for his journey into the spiritual world.",
      #     "released": "1996-05-05",
      #     "languages": ["en", "cr"],
      #     "subgenres": ["19th-century", "murder", "black-and-white", "sheriff", "bounty-hunter", "frontier"],
      #     "updated_at": "2025-12-05T16:23:26.000Z",
      #     "after_credits": false,
      #     "certification": "R",
      #     "comment_count": 6,
      #     "during_credits": false,
      #     "original_title": "Dead Man",
      #     "available_translations": ["bg", "ca", "cs", "da", "de", "el", "en", "es", "fi", "fr", "he", "hu", "it", "ja", "ka", "ko", "lt", "nl", "no", "pl", "pt", "ru", "sk", "sv", "tr", "uk", "zh"]
      #   },
      #   "plays": 1,
      #   "total_count": 479
      # }, {
      def history
        conn.get("/users/me/watched/movies").body
      end

      def conn
        @conn ||= Faraday.new("https://api.trakt.tv") do |conn|
          conn.headers['trakt-api-key'] = CLIENT_ID
          conn.headers['trakt-api-version'] = "2"

          conn.request :authorization, 'Bearer', ACCESS_TOKEN
          conn.request :json

          # conn.use Lebowski::Trakt::Pagination

          conn.response :json
          conn.response :raise_error
        end
      end
    end

    # borked
    class Pagination < ::Faraday::Middleware
      def call(env)
        response = @app.call(env)

        response.on_complete do |res_env|
          current_page = res_env.response_headers['X-Pagination-Page'].to_i
          page_count = res_env.response_headers['X-Pagination-Page-Count'].to_i
          next if current_page >= page_count

          encoder = env.params_encoder || ::Faraday::FlatParamsEncoder

          paged_env = env.dup
          paged_env.url = env.url.dup

          params = encoder.decode(paged_env.url.query.to_s)
          params['page'] = (current_page + 1).to_s
          paged_env.url.query = encoder.encode(params)

          paged_response = call(paged_env)
          paged_response.on_complete do |paged_res_env|
            res_env.body.concat(paged_res_env.body)
          end
        end

        response
      end
    end

  end
end
