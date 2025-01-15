import axios from "axios";

export class TMDBClient {
  constructor(accessToken) {
    this.client = axios.create({
      baseURL: "https://api.themoviedb.org",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
      },
    });
  }

  // {"id": 115,
  //   "results": {
  //     "CA": {
  //       "link": "https://www.themoviedb.org/movie/115-the-big-lebowski/watch?locale=CA",
  //       "buy": [
  //         {
  //           "logo_path": "/9ghgSC0MA082EL6HLCW3GalykFD.jpg",
  //           "provider_id": 2,
  //           "provider_name": "Apple TV",
  //           "display_priority": 6
  //         },
  //       ],
  //       "rent": [
  //         {
  //           "logo_path": "/9ghgSC0MA082EL6HLCW3GalykFD.jpg",
  //           "provider_id": 2,
  //           "provider_name": "Apple TV",
  //           "display_priority": 6
  //         },
  //       ],
  //       "ads": [
  //         {
  //           "logo_path": "/o4JMLTkDfjei1XrsVk1vSjXfdBk.jpg",
  //           "provider_id": 73,
  //           "provider_name": "Tubi TV",
  //           "display_priority": 15
  //         }
  //       ]
  //     },
  async providers(movieId) {
    const response = await this.client.get(`/3/movie/${movieId}/watch/providers`);
    return response.data.results["CA"] || {};
  }
}
