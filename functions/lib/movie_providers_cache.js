import {getFirestore} from "firebase-admin/firestore";

export class MovieProvidersCache {
  constructor() {
    this.cache = {};
  }

  set(movieId, providers) {
    this.cache[movieId] = providers;
  }

  async save() {
    const collection = getFirestore().collection("movieProviders");
    await Promise.all(Object.keys(this.cache).map(async (movieId) => {
      const providers = this.cache[movieId];
      await collection.doc(movieId).set({
        lastUpdated: Date.now(),
        providers,
      });
    }));
  }
}
