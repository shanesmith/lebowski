require 'faraday'

module Lebowski
  class TMDB
    AccessToken = ENV['TMDB_ACCESS_TOKEN']

    class <<self

      # {"id": 115,
      #   "results": {
      #     "CA": {
      #       "link": "https://www.themoviedb.org/movie/115-the-big-lebowski/watch?locale=CA",
      #       "buy": [
      #         {
      #           "logo_path": "/9ghgSC0MA082EL6HLCW3GalykFD.jpg",
      #           "provider_id": 2,
      #           "provider_name": "Apple TV",
      #           "display_priority": 6
      #         },
      #       ],
      #       "rent": [
      #         {
      #           "logo_path": "/9ghgSC0MA082EL6HLCW3GalykFD.jpg",
      #           "provider_id": 2,
      #           "provider_name": "Apple TV",
      #           "display_priority": 6
      #         },
      #       ],
      #       "ads": [
      #         {
      #           "logo_path": "/o4JMLTkDfjei1XrsVk1vSjXfdBk.jpg",
      #           "provider_id": 73,
      #           "provider_name": "Tubi TV",
      #           "display_priority": 15
      #         }
      #       ]
      #     },
      def providers(id)
        conn.get("/3/movie/#{id}/watch/providers").body.dig("results", "CA")
      end

      def conn
        @conn ||= Faraday.new("https://api.themoviedb.org") do |conn|
          conn.request :authorization, 'Bearer', AccessToken
          conn.request :json

          conn.response :raise_error
          conn.response :json
        end
      end
    end
  end
end
