import {onSchedule} from "firebase-functions/v2/scheduler";
import {initializeApp} from "firebase-admin/app";
import {defineSecret} from "firebase-functions/params";

import User from "./lib/user.js";
import TraktClient from "./lib/trakt.js";

const traktClientId = defineSecret("TRAKT_CLIENT_ID");
const traktClientSecret = defineSecret("TRAKT_CLIENT_SECRET");

initializeApp();

function getTraktClient() {
  return new TraktClient(
      traktClientId.value(),
      traktClientSecret.value(),
  );
}

// TODO set CORS
export const countTheThings = onSchedule(
    {
      schedule: "0 21 * * *", // 9pm UTC
      secrets: [traktClientId, traktClientSecret],
    },
    async () => {
      const userList = await User.getAll(getTraktClient());
      userList.forEach(async (user) => {
        const watchlist = await user.getWatchlist();
        user.updatePrefs({watchlistCount: watchlist.length});
      });
    },
);
