import {onRequest} from "firebase-functions/v2/https";
import {onDocumentUpdated} from "firebase-functions/v2/firestore";
import * as logger from "firebase-functions/logger";
import * as admin from "firebase-admin";

const cors = require("cors");
const fetch = require("node-fetch");
const {GoogleAuth} = require("google-auth-library");

const corsHandler = cors({origin: true});

admin.initializeApp();
const GCLOUD_PROJECT = process.env.GCLOUD_PROJECT || "encoretouring";
const db = admin.firestore();

// --- Reusable Helper Functions ---

async function getTokensForTour(tourId: string): Promise<string[]> {
  const crewSnapshot = await db.collection("tourCrew")
      .where("tourId", "==", tourId)
      .where("status", "==", "accepted")
      .get();
  if (crewSnapshot.empty) return [];

  const userIds = crewSnapshot.docs.map((doc) => doc.data().userId).filter((id) => id);
  if (userIds.length === 0) return [];

  const userDocs = await db.collection("users").where(admin.firestore.FieldPath.documentId(), "in", userIds).get();
  return [...new Set(userDocs.docs.flatMap((doc) => doc.data().fcmTokens || []))];
}

async function sendFcmMessages(tokens: string[], notification: {title: string, body: string}) {
  if (tokens.length === 0) {
    logger.info("No tokens provided to sendFcmMessages. Skipping.");
    return;
  }

  const auth = new GoogleAuth({
    scopes: "https://www.googleapis.com/auth/firebase.messaging",
  });
  const accessToken = await auth.getAccessToken();
  const fcmEndpoint = `https://fcm.googleapis.com/v1/projects/${GCLOUD_PROJECT}/messages:send`;

  const sendPromises = tokens.map((token: string) => {
    const fcmPayload = {
      message: {
        token: token,
        notification: notification,
      },
    };
    return fetch(fcmEndpoint, {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${accessToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(fcmPayload),
    });
  });

  await Promise.all(sendPromises);
}


// --- Firestore Triggered Function (UPDATED) ---

export const onItineraryUpdate = onDocumentUpdated("itineraryItems/{itemId}", async (event) => {
  if (!event.data) return;

  const before = event.data.before.data();
  const after = event.data.after.data();

  let changeDescription = "";
  if (before.title !== after.title) {
    changeDescription = `${before.title} is now ${after.title}.`;
  } else if (before.timeUTC.toMillis() !== after.timeUTC.toMillis()) {
    const timeZone = after.timezone || "UTC";
    const options: Intl.DateTimeFormatOptions = {
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
      timeZone: timeZone,
    };
    const oldTime = new Date(before.timeUTC.toMillis()).toLocaleTimeString("en-US", options);
    const newTime = new Date(after.timeUTC.toMillis()).toLocaleTimeString("en-US", options);
    changeDescription = `${after.title} time changed from ${oldTime} to ${newTime}.`;
  } else {
    return;
  }

  const tourId = after.tourId;
  if (!tourId) return;

  const tourDoc = await db.collection("tours").doc(tourId).get();
  const tourName = tourDoc.data()?.tourName || "Tour Update";
  const tokens = await getTokensForTour(tourId);

  await sendFcmMessages(tokens, {title: tourName, body: changeDescription});
});


// --- HTTP Callable Function ---

export const sendBroadcastNotification = onRequest(async (req, res) => {
  corsHandler(req, res, async () => {
    try {
      const authHeader = req.headers.authorization;
      if (!authHeader || !authHeader.startsWith("Bearer ")) {
        return res.status(401).send("Unauthorized");
      }
      const idToken = authHeader.split("Bearer ")[1];
      const decodedToken = await admin.auth().verifyIdToken(idToken);
      const senderId = decodedToken.uid;

      const {tourId, message} = req.body.data;
      if (!tourId || !message) {
        return res.status(400).send({error: "Invalid request body."});
      }

      const tourDoc = await db.collection("tours").doc(tourId).get();
      if (!tourDoc.exists || tourDoc.data()?.ownerId !== senderId) {
        return res.status(403).send({error: "Permission denied."});
      }
      const tourName = tourDoc.data()?.tourName || "a tour";

      const tokens = await getTokensForTour(tourId);
      if (tokens.length === 0) {
        return res.status(200).send({data: {success: true, message: "No crew members to notify."}});
      }

      await sendFcmMessages(tokens, {title: `Broadcast: ${tourName}`, body: message});
      return res.status(200).send({data: {success: true}});
    } catch (error) {
      logger.error("Broadcast failed:", error);
      return res.status(500).send({error: "An internal error occurred."});
    }
  });
});
