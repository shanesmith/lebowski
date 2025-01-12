const {onCall, HttpsError} = require("firebase-functions/v2/https");
const {initializeApp} = require("firebase-admin/app");
const {getFirestore} = require("firebase-admin/firestore");
// const logger = require("firebase-functions/logger");

initializeApp();

function requireAuth(request) {
  if (request.auth) {
    return;
  }

  throw new HttpsError("unauthenticated");
}

async function getUserPrefs(request) {
  requireAuth(request);

  const snapshot = await getFirestore()
      .doc(`users/${request.auth.uid}`)
      .get();

  if (!snapshot.exists) {
    return new HttpsError("not-found");
  }

  return snapshot.data();
}

// TODO set CORS
exports.doTheThing = onCall(async (request) => {
  const prefs = await getUserPrefs(request);
  return prefs;
});
