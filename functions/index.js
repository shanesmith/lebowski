import {onSchedule} from "firebase-functions/v2/scheduler";
import {initializeApp} from "firebase-admin/app";
import {defineSecret} from "firebase-functions/params";

import {User} from "./lib/user.js";
import {TraktClient} from "./lib/trakt.js";
import {TMDBClient} from "./lib/tmdb.js";
import {MovieProvidersCache} from "./lib/movie_providers_cache.js";

const traktClientId = defineSecret("TRAKT_CLIENT_ID");
const traktClientSecret = defineSecret("TRAKT_CLIENT_SECRET");

const tmdbAccesstoken = defineSecret("TMDB_ACCESS_TOKEN");

initializeApp();

function getTraktClient() {
  return new TraktClient(
      traktClientId.value(),
      traktClientSecret.value(),
  );
}

function getTMDBClient() {
  return new TMDBClient(tmdbAccesstoken.value());
}

// TODO set CORS
// TODO parallelize
export const countTheThings = onSchedule(
    {
      schedule: "0 21 * * *", // 9pm UTC
      secrets: [traktClientId, traktClientSecret, tmdbAccesstoken],
    },
    async () => {
      const tmdbClient = getTMDBClient();
      const movieProvidersCache = new MovieProvidersCache();

      const userList = await User.getAll(getTraktClient());
      await Promise.all(userList.map(async (user) => {
        const watchlist = await user.getWatchlist();
        user.updatePrefs({watchlistCount: watchlist.length});

        await Promise.all(watchlist.map(async (entry) => {
          const movieId = entry.movie.ids.tmdb;
          const providers = await tmdbClient.providers(movieId);
          movieProvidersCache.set(movieId, providers);
        }));
      }));


      await movieProvidersCache.save();
    },
);
