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

      return admin.firestore().doc(`sharedItineraries/${itineraryId}`).get()
          .then((itineraryDoc) => {
            if (!itineraryDoc.exists) {
              throw new Error("Shared itinerary not found");
            }

            const itinerary = itineraryDoc.data();
            const itineraryOwnerId = itinerary.userId;

            return admin.firestore().doc(`users/${itineraryOwnerId}`).get();
          })
          .then((userDoc) => {
            if (!userDoc.exists) {
              throw new Error("User not found");
            }

            const user = userDoc.data();
            const fcmToken = user.fcmToken;

            // Break long strings
            const title = "Your itinerary was liked!";
            const body = `${newLike.username} liked your shared itinerary.`;

            const message = {
              token: fcmToken,
              notification: {title, body},
            };

            return admin.messaging().send(message);
          })
          .catch((error) => {
            console.log("Error sending notification", error);
            throw error;
          });
    });