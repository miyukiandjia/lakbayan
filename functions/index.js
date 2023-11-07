const functions = require("firebase-functions");
const {Storage} = require("@google-cloud/storage");
const path = require("path");
const os = require("os");
const fs = require("fs");
const {GoogleAuth} = require("google-auth-library");

process.env.GCLOUD_PROJECT = "lakbayan-e1d48";
const projectId = "lakbayan-e1d48";

const admin = require("firebase-admin");
admin.initializeApp({
  projectId: projectId,
  credential: admin.credential.applicationDefault(),
});

exports.sendLikeNotification = functions.firestore
    .document("sharedItineraries/{itineraryId}/likes/{likeId}")
    .onCreate((snap, context) => {
      const itineraryId = context.params.itineraryId;
      const newLike = snap.data();
      let itineraryOwnerId;

      return admin.firestore().doc(`sharedItineraries/${itineraryId}`).get()
          .then((itineraryDoc) => {
            if (!itineraryDoc.exists) {
              throw new Error("Shared itinerary not found");
            }

            const itinerary = itineraryDoc.data();
            itineraryOwnerId = itinerary.userId;

            return admin.firestore().doc(`users/${itineraryOwnerId}`).get();
          })
          .then((userDoc) => {
            if (!userDoc.exists) {
              throw new Error("User not found");
            }

            const user = userDoc.data();
            const fcmToken = user.fcmToken;
            const title = "Your itinerary was liked!";
            const body = `${newLike.username} liked your shared itinerary.`;

            const message = {
              token: fcmToken,
              notification: {title, body},
            };

            return admin.messaging().send(message);
          })
          .then(() => {
            const fromUserId = context.params.likeId;
            const logEntry = {
              type: "itinerary_like",
              itineraryId,
              fromUserId,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            };

            return admin.firestore()
                .collection(`users/${itineraryOwnerId}/notificationsLog`)
                .add(logEntry);
          })
          .catch((error) => {
            console.error("Error sending notification", error);
            throw error;
          });
    });

exports.sendPostLikeNotification = functions.firestore
    .document("posts/{postId}/likes/{likeId}")
    .onCreate((snap, context) => {
      const postId = context.params.postId;
      const newLike = snap.data();
      let postOwnerId;

      return admin.firestore().doc(`posts/${postId}`).get()
          .then((postDoc) => {
            if (!postDoc.exists) {
              throw new Error("Post not found");
            }

            const post = postDoc.data();
            postOwnerId = post.userId;
            console.log(`Post Owner ID: ${postOwnerId}`);

            return admin.firestore().doc(`users/${postOwnerId}`).get();
          })
          .then((userDoc) => {
            if (!userDoc.exists) {
              throw new Error("User not found");
            }

            const user = userDoc.data();
            const fcmToken = user.fcmToken;
            console.log(`FCM Token: ${fcmToken}`);

            const title = "Your post was liked!";
            const body = `${newLike.username} liked your post.`;
            const message = {
              token: fcmToken,
              notification: {title, body},
            };

            return admin.messaging().send(message);
          })
          .then(() => {
            const logEntry = {
              type: "post_like",
              postId,
              fromUserId: newLike.userId,
              timestamp: admin.firestore.FieldValue.serverTimestamp(),
            };
            console.log(`Log Entry: ${JSON.stringify(logEntry)}`);

            return admin.firestore()
                .collection(`users/${postOwnerId}/notificationsLog`)
                .add(logEntry);
          })
          .catch((error) => {
            console.error("Error sending notification or logging", error);
          });
    });

exports.removeLikeNotification = functions.firestore
    .document("sharedItineraries/{itineraryId}/likes/{likeId}")
    .onDelete((snap, context) => {
      const itineraryId = context.params.itineraryId;
      let itineraryOwnerId;

      return admin.firestore().doc(`sharedItineraries/${itineraryId}`).get()
          .then((itineraryDoc) => {
            if (!itineraryDoc.exists) {
              return null;
            }

            const itinerary = itineraryDoc.data();
            itineraryOwnerId = itinerary.userId;

            return admin.firestore()
                .collection(`users/${itineraryOwnerId}/notificationsLog`)
                .where("type", "==", "itinerary_like")
                .where("fromUserId", "==", context.params.likeId)
                .where("itineraryId", "==", itineraryId)
                .limit(1)
                .get();
          })
          .then((querySnapshot) => {
            if (!querySnapshot.empty) {
              const logDoc = querySnapshot.docs[0];
              return logDoc.ref.delete();
            }
            return null;
          })
          .catch((error) => {
            console.error("Error removing notification log", error);
          });
    });

exports.removePostLikeNotification = functions.firestore
    .document("posts/{postId}/likes/{likeId}")
    .onDelete((snap, context) => {
      const postId = context.params.postId;
      const removedLike = snap.data();
      let postOwnerId;

      return admin.firestore().doc(`posts/${postId}`).get()
          .then((postDoc) => {
            if (!postDoc.exists) {
              return null;
            }

            const post = postDoc.data();
            postOwnerId = post.userId;

            return admin.firestore()
                .collection(`users/${postOwnerId}/notificationsLog`)
                .where("type", "==", "post_like")
                .where("fromUserId", "==", removedLike.userId)
                .where("postId", "==", postId)
                .limit(1)
                .get();
          })
          .then((querySnapshot) => {
            if (!querySnapshot.empty) {
              const logDoc = querySnapshot.docs[0];
              return logDoc.ref.delete();
            }
            return null;
          })
          .catch((error) => {
            console.error("Error removing notification log", error);
          });
    });
