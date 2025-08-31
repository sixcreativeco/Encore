import {onRequest} from "firebase-functions/v2/https";
import {onDocumentUpdated, onDocumentCreated} from "firebase-functions/v2/firestore";
import {onSchedule} from "firebase-functions/v2/scheduler";
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


// --- Firestore Triggered Function (Itinerary Updates) ---

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


// --- Firestore Triggered Function (Ticket Availability) ---

interface TicketType {
  name: string;
  allocation: number;
  availability?: {
    type: string;
  };
}

interface TicketedEvent {
  ticketTypes: TicketType[];
  earlyBirdSoldOutNotified?: boolean;
  ownerId: string;
  showId: string;
  tourId: string;
}

export const onTicketSaleCreateCheckAvailability = onDocumentCreated("ticketSales/{saleId}", async (event) => {
  const saleSnap = event.data;
  if (!saleSnap) {
    logger.log("No data associated with the event.");
    return;
  }
  const saleData = saleSnap.data();
  const eventId = saleData.ticketedEventId;

  if (!eventId) {
    logger.log(`Ticket sale ${saleSnap.id} is missing an eventId.`);
    return;
  }

  logger.log(`Checking ticket availability for event: ${eventId}`);

  const eventRef = db.collection("ticketedEvents").doc(eventId);

  return db.runTransaction(async (transaction) => {
    const eventDoc = await transaction.get(eventRef);
    if (!eventDoc.exists) {
      logger.error(`Event document ${eventId} not found.`);
      return;
    }

    const eventData = eventDoc.data() as TicketedEvent;

    if (eventData.earlyBirdSoldOutNotified) {
      logger.log(`Notification for event ${eventId} already sent. Skipping.`);
      return;
    }

    const ticketTypes: TicketType[] = eventData.ticketTypes;

    const earlyBirdSoldOut = ticketTypes.some(
      (tt) => tt.availability?.type === "Early Bird" && tt.allocation <= 0
    );

    if (earlyBirdSoldOut) {
      logger.log(`Early Bird tickets for event ${eventId} have sold out. Creating notification.`);

      const showDoc = await db.collection("shows").doc(eventData.showId).get();
      const tourDoc = await db.collection("tours").doc(eventData.tourId).get();
      const showName = showDoc.data()?.city || "a show";
      const tourName = tourDoc.data()?.tourName || "your tour";
      const artistName = tourDoc.data()?.artist || "";
      const message = `Early Bird tickets for ${artistName} in ${showName} have sold out. Release the next ticket type?`;

      const notification = {
        recipientId: eventData.ownerId,
        tourId: eventData.tourId,
        showId: eventData.showId,
        ticketedEventId: eventId,
        type: "EARLY_BIRD_SOLD_OUT",
        message: message,
        tourName: tourName,
        artistName: artistName,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isRead: false,
      };

      await db.collection("notifications").add(notification);
      transaction.update(eventRef, { earlyBirdSoldOutNotified: true });
      logger.log(`Successfully created sold-out notification for owner ${eventData.ownerId}.`);
    }
  });
});


// --- HTTP Callable Function (Broadcast) ---

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


// --- Scheduled Function (Ticket Publishing) ---

export const checkScheduledTicketEvents = onSchedule("every 5 minutes", async (event) => {
  logger.log("Running scheduled job to check for ticket events to publish...");

  const now = admin.firestore.Timestamp.now();

  const query = db.collection("ticketedEvents")
    .where("status", "==", "Scheduled")
    .where("onSaleDate", "<=", now);

  try {
    const snapshot = await query.get();

    if (snapshot.empty) {
      logger.log("No scheduled events to publish at this time.");
      return;
    }

    const batch = db.batch();
    snapshot.docs.forEach((doc) => {
      logger.log(`Publishing event: ${doc.id}`);
      const eventRef = db.collection("ticketedEvents").doc(doc.id);
      batch.update(eventRef, {
        status: "Published",
        lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    });

    await batch.commit();

    logger.log(`Successfully published ${snapshot.size} ticketed event(s).`);
    return;
  } catch (error) {
    logger.error("Error publishing scheduled ticket events:", error);
    return;
  }
});

// --- THIS IS THE NEW FUNCTION ---
export const onShowCreate = onDocumentCreated("shows/{showId}", async (event) => {
    const showSnap = event.data;
    if (!showSnap) {
        logger.log("No data associated with the event, exiting.");
        return;
    }

    const showData = showSnap.data();
    const tourId = showData.tourId;
    const showId = showSnap.id;
    const ownerId = showData.ownerId;

    if (!tourId || !ownerId) {
        logger.error("Show is missing tourId or ownerId.", { showId });
        return;
    }

    const db = admin.firestore();

    try {
        logger.log(`New show created (${showId}). Creating draft TicketedEvent.`);

        const existingEventQuery = db.collection("ticketedEvents").where("showId", "==", showId).limit(1);
        const existingEventSnapshot = await existingEventQuery.get();
        if (!existingEventSnapshot.empty) {
            logger.warn(`TicketedEvent already exists for show ${showId}. Aborting.`);
            return;
        }

        const tourDoc = await db.collection("tours").doc(tourId).get();
        const tourData = tourDoc.data();

        const newEventData = {
            ownerId: ownerId,
            tourId: tourId,
            showId: showId,
            status: "Draft",
            description: tourData?.defaultEventDescription || `Get ready for an incredible night with ${tourData?.artist || 'the artist'} in ${showData.city}!`,
            importantInfo: tourData?.defaultImportantInfo || null,
            ticketTypes: tourData?.defaultTicketTypes || [{
                id: admin.firestore.FieldValue.serverTimestamp().toString(),
                name: "General Admission",
                allocation: 100,
                price: 0.00,
                currency: "NZD",
                availability: { type: "Always Available" }
            }],
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            lastUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        await db.collection("ticketedEvents").add(newEventData);
        logger.log(`✅ Successfully created draft TicketedEvent for show ${showId}.`);

    } catch (error) {
        logger.error(`Error creating TicketedEvent for show ${showId}:`, error);
    }
});