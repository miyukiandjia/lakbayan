const functions = require("firebase-functions");
const {Storage} = require("@google-cloud/storage");
const path = require("path");
const os = require("os");
const fs = require("fs");
const {GoogleAuth} = require("google-auth-library");
process.env.GCLOUD_PROJECT = 'lakbayanv2';
// Set your project ID here
const projectId = 'lakbayanv2';

// Initialize Firebase Admin with project ID and default credentials
const admin = require('firebase-admin');
admin.initializeApp({
  projectId: projectId,
  credential: admin.credential.applicationDefault()
});


exports.sendLikeNotification = functions.firestore
  .document("sharedItineraries/{itineraryId}/likes/{likeId}")
  .onCreate((snap, context) => {
    const itineraryId = context.params.itineraryId;
    const newLike = snap.data();
    let itineraryOwnerId; // Define at a higher scope

    return admin.firestore().doc(`sharedItineraries/${itineraryId}`).get()
      .then((itineraryDoc) => {
        if (!itineraryDoc.exists) {
          throw new Error("Shared itinerary not found");
        }

        const itinerary = itineraryDoc.data();
        itineraryOwnerId = itinerary.userId; // Assign the variable here

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
          notification: { title, body },
        };

        console.log(`FCM Token server side: ${fcmToken}`);
        return admin.messaging().send(message);
      })
      .then(() => {
        const fromUserId = context.params.likeId;
        // After sending the notification, log the like event in the notifications log
        const logEntry = {
          type: 'itinerary_like',
          itineraryId: itineraryId,
          fromUserId: fromUserId,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        };

        // Write the log entry to the notificationsLog of the itinerary owner
        return admin.firestore()
          .collection(`users/${itineraryOwnerId}/notificationsLog`)
          .add(logEntry);
      })
      .catch((error) => {
        console.log("Error sending notification", error);
        throw error;
      });
  });
  exports.sendPostLikeNotification = functions.firestore
  .document("posts/{postId}/likes/{likeId}")
  .onCreate((snap, context) => {
    const postId = context.params.postId;
    const newLike = snap.data();
    let postOwnerId; // Define at a higher scope

    return admin.firestore().doc(`posts/${postId}`).get()
      .then((postDoc) => {
        if (!postDoc.exists) {
          throw new Error("Post not found");
        }

        const post = postDoc.data();
        postOwnerId = post.userId; // Assign the variable here
        console.log(`Post Owner ID: ${postOwnerId}`); // Debugging log

        return admin.firestore().doc(`users/${postOwnerId}`).get();
      })
      .then((userDoc) => {
        if (!userDoc.exists) {
          throw new Error("User not found");
        }

        const user = userDoc.data();
        const fcmToken = user.fcmToken;
        console.log(`FCM Token: ${fcmToken}`); // Debugging log

        const title = "Your post was liked!";
        const body = `${newLike.username} liked your post.`;

        const message = {
          token: fcmToken,
          notification: { title, body },
        };

        return admin.messaging().send(message);
      })
      .then(() => {
        const logEntry = {
          type: 'post_like',
          postId: postId,
          fromUserId: newLike.userId,
          timestamp: admin.firestore.FieldValue.serverTimestamp()
        };
        console.log(`Log Entry: ${JSON.stringify(logEntry)}`); // Debugging log

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
    const removedLike = snap.data();
    let itineraryOwnerId;

    // Fetch the itinerary owner's ID
    return admin.firestore().doc(`sharedItineraries/${itineraryId}`).get()
      .then((itineraryDoc) => {
        if (!itineraryDoc.exists) {
          return null; // No need to throw an error, just exit
        }

        const itinerary = itineraryDoc.data();
        itineraryOwnerId = itinerary.userId;

        // Query the notificationsLog for the log entry corresponding to the like
        return admin.firestore()
          .collection(`users/${itineraryOwnerId}/notificationsLog`)
          .where('type', '==', 'itinerary_like')
          .where('fromUserId', '==', context.params.likeId)
          .where('itineraryId', '==', itineraryId)
          .limit(1)
          .get();
      })
      .then((querySnapshot) => {
        // If a corresponding log entry is found, delete it
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

    // Fetch the post owner's ID
    return admin.firestore().doc(`posts/${postId}`).get()
      .then((postDoc) => {
        if (!postDoc.exists) {
          return null; // No need to throw an error, just exit
        }

        const post = postDoc.data();
        postOwnerId = post.userId;

        // Query the notificationsLog for the log entry corresponding to the like
        return admin.firestore()
          .collection(`users/${postOwnerId}/notificationsLog`)
          .where('type', '==', 'post_like')
          .where('fromUserId', '==', removedLike.userId)
          .where('postId', '==', postId)
          .limit(1)
          .get();
      })
      .then((querySnapshot) => {
        // If a corresponding log entry is found, delete it
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


