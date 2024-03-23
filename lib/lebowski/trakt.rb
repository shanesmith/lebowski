require 'faraday'

# https://www.hansschnedlitz.com/2021/02/26/cli-oauth-in-ruby.html

module Lebowski
  class Trakt
    ClientId = ENV['TRAKT_CLIENT_ID']
    ClientSecret = ENV['TRAKT_CLIENT_SECRET']
    AccessToken = ENV['TRAKT_ACCESS_TOKEN']

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
      def wishlist
        conn.get("/users/me/watchlist/movies/added").body
      end

      def conn
        @conn ||= Faraday.new("https://api.trakt.tv") do |conn|
          conn.headers['trakt-api-key'] = ClientId
          conn.headers['trakt-api-version'] = "2"

          conn.request :authorization, 'Bearer', AccessToken
          conn.request :json

          conn.response :json
          conn.response :raise_error
        end
      end
    end
  end
end
