import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

admin.initializeApp();

const db = admin.firestore();

/**
 * Triggers when a new alert is created.
 * Queries receiver's token and dispatches high-priority push message.
 */
export const onAlertCreated = functions.firestore
  .document("alerts/{alertId}")
  .onCreate(async (snap, context) => {
    const alertData = snap.data();
    if (!alertData) return;

    const senderUid = alertData.senderUid;
    const receiverUid = alertData.receiverUid;
    const alertType = alertData.alertType;
    const alertId = context.params.alertId;

    try {
      // 1. Fetch sender name
      const senderDoc = await db.collection("users").doc(senderUid).get();
      const senderName = senderDoc.data()?.name || "Partner";

      // 2. Fetch receiver fcmToken
      const receiverDoc = await db.collection("users").doc(receiverUid).get();
      const receiverToken = receiverDoc.data()?.fcmToken;

      if (!receiverToken) {
        console.log(`No FCM token registered for receiver: ${receiverUid}`);
        return;
      }

      // 3. Dispatch high priority data payload (forces background broadcast wake)
      const message: admin.messaging.Message = {
        token: receiverToken,
        data: {
          alertId: alertId,
          alertType: alertType,
          senderName: senderName,
        },
        android: {
          priority: "high",
          ttl: 10 * 1000, // 10 seconds live TTL
        },
      };

      await admin.messaging().send(message);
      console.log(`Successfully dispatched Alert ${alertId} to device token.`);

    } catch (error) {
      console.error("Error dispatching alert notification:", error);
    }
  });

/**
 * Triggers when an alert status is modified.
 * Dispatches notification to sender when status becomes 'acknowledged'.
 */
export const onAlertAcknowledged = functions.firestore
  .document("alerts/{alertId}")
  .onUpdate(async (change, context) => {
    const nextData = change.after.data();
    const prevData = change.before.data();

    if (!nextData || !prevData) return;

    // Check if transition is to acknowledged state
    if (nextData.status === "acknowledged" && prevData.status !== "acknowledged") {
      const senderUid = nextData.senderUid;
      const receiverUid = nextData.receiverUid;
      const alertType = nextData.alertType.toUpperCase();

      try {
        // 1. Fetch receiver (acknowledger) name
        const receiverDoc = await db.collection("users").doc(receiverUid).get();
        const receiverName = receiverDoc.data()?.name || "Partner";

        // 2. Fetch sender (original alert creator) token
        const senderDoc = await db.collection("users").doc(senderUid).get();
        const senderToken = senderDoc.data()?.fcmToken;

        if (!senderToken) {
          console.log(`No FCM token registered for original sender: ${senderUid}`);
          return;
        }

        // 3. Dispatch notification push confirmation
        const message: admin.messaging.Message = {
          token: senderToken,
          notification: {
            title: "Alert Acknowledged!",
            body: `${receiverName} acknowledged your ${alertType}.`,
          },
          android: {
            priority: "high",
            notification: {
              clickAction: "FLUTTER_NOTIFICATION_CLICK",
            },
          },
        };

        await admin.messaging().send(message);
        console.log(`Dispatched acknowledgement confirmation push to original sender.`);

      } catch (error) {
        console.error("Error sending ack notification:", error);
      }
    }
  });
