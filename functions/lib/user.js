import {HttpsError} from "firebase-functions/v2/https";
import {getFirestore} from "firebase-admin/firestore";

export default class User {
  constructor(uid, traktClient) {
    this.uid = uid;
    this.traktClient = traktClient;
  }

  static async getAll(traktClient) {
    const documentList = await getFirestore()
        .collection("users")
        .listDocuments();

    return documentList.map((doc) => new User(doc.id, traktClient));
  }

  async getPrefs() {
    const snapshot = await getFirestore()
        .doc(`users/${this.uid}`)
        .get();

    if (!snapshot.exists) {
      return new HttpsError("not-found");
    }

    return snapshot.data();
  }

  updatePrefs(prefs) {
    return getFirestore()
        .doc(`users/${this.uid}`)
        .set(prefs, {merge: true});
  }

  async getTraktToken() {
    const prefs = await this.getPrefs();
    return prefs.traktAuth.access_token;
  }

  async getWatchlist() {
    const traktToken = await this.getTraktToken();
    return this.traktClient.watchlist(traktToken);
  }
}
