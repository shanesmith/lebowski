import axios from "axios";

export class TraktClient {
  constructor(clientId, _clientSecret) {
    this.client = axios.create({
      baseURL: "https://api.trakt.tv",
      headers: {
        "trakt-api-key": clientId,
        "trakt-api-version": "2",
      },
    });
  }

  setAccessToken(token) {
    this.client.defaults.headers.common["Authorization"] = `Bearer ${token}`;
  }

  // [{"rank"=>1,
  //   "id"=>985612439,
  //   "listed_at"=>"2024-02-24T14:07:17.000Z",
  //   "notes"=>nil,
  //   "type"=>"movie",
  //   "movie"=>
  //      {"title"=>"Hundreds of Beavers",
  //       "year"=>2024,
  //       "ids"=>{
  //         "trakt"=>820070,
  //         "slug"=>"hundreds-of-beavers-2024",
  //         "imdb"=>"tt12818328",
  //         "tmdb"=>1019939}}},
  async watchlist(token) {
    const response = await this.client.get(
        "/users/me/watchlist/movies/added",
        {
          headers: {"Authorization": `Bearer ${token}`},
        },
    );
    return response.data;
  }
}
