# ![The Dude](https://shanesmith.github.io/lebowski/assets/the_dude.png) [Lebowski](https://shanesmith.github.io/lebowski)

_This app really ties the room together._

<hr>

Grouping of my [watchlist][1] movies by streaming providers. 

A Github Workflow runs daily to pull my watchlist from the [Trakt API][2] and
finds streaming providers for each movie using [JustWatch][4] data provided by
the [TMDB API][3]. The resulting data is processed and dumped in a JSON file.
The workflow then publishes this JSON file to Github Pages together with a
simple Vue.js based webapp for viewing.

[1]: https://trakt.tv/users/shanesmith/watchlist?display=movie&sort=added,asc
[2]: https://trakt.docs.apiary.io/#reference/users/watchlist
[3]: https://developer.themoviedb.org/reference/movie-watch-providers
[4]: https://www.justwatch.com

