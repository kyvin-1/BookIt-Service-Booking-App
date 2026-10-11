const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const logger = require("firebase-functions/logger");

const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

initializeApp();

const db = getFirestore();

/**
 * Sends an FCM notification whenever a booking status changes.
 *
 * Flow:
 * Admin changes booking status
 *        ↓
 * Firestore bookings/{bookingId}
 *        ↓
 * Cloud Function detects the change
 *        ↓
 * Gets customer's fcmToken
 *        ↓
 * Sends notification to customer
 */
exports.sendBookingStatusNotification = onDocumentUpdated(
  "bookings/{bookingId}",
  async (event) => {
    const before = event.data.before.data();
    const after = event.data.after.data();

    if (!before || !after) {
      return null;
    }

    const oldStatus = before.status ?? "pending";
    const newStatus = after.status ?? "pending";

    // Only continue when the status actually changed.
    if (oldStatus === newStatus) {
      return null;
    }

    // Only send notifications for these statuses.
    const allowedStatuses = [
      "confirmed",
      "completed",
      "cancelled",
    ];

    if (!allowedStatuses.includes(newStatus)) {
      return null;
    }

    const bookingId = event.params.bookingId;
    const userId = after.userId;

    if (!userId) {
      logger.warn("Booking has no userId.", {
        bookingId,
      });

      return null;
    }

    // Get the customer document.
    const userSnapshot = await db
      .collection("users")
      .doc(userId)
      .get();

    if (!userSnapshot.exists) {
      logger.warn("Customer document not found.", {
        bookingId,
        userId,
      });

      return null;
    }

    const userData = userSnapshot.data() || {};
    const token = userData.fcmToken;

    if (!token) {
      logger.warn("Customer has no FCM token.", {
        bookingId,
        userId,
      });

      return null;
    }

    const providerName =
      after.providerName || "your service provider";

    const service =
      after.service || "your service";

    let title = "Booking Updated";
    let body =
      `Your ${service} booking with ${providerName} has been updated.`;

    if (newStatus === "confirmed") {
      title = "Booking Confirmed";

      body =
        `Your ${service} booking with ${providerName} has been confirmed.`;
    }

    if (newStatus === "completed") {
      title = "Booking Completed";

      body =
        `Your ${service} booking with ${providerName} has been completed. You can now leave a review.`;
    }

    if (newStatus === "cancelled") {
      title = "Booking Cancelled";

      body =
        `Your ${service} booking with ${providerName} has been cancelled.`;
    }

    try {
      const response = await getMessaging().send({
        token: token,

        notification: {
          title: title,
          body: body,
        },

        data: {
          bookingId: bookingId,
          status: newStatus,
          screen: "my_bookings",
        },

        android: {
          notification: {
            channelId: "bookit_booking_channel",
            sound: "default",
          },
        },
      });

      logger.info("Booking notification sent successfully.", {
        bookingId,
        userId,
        status: newStatus,
        response,
      });
    } catch (error) {
      logger.error("Failed to send booking notification.", {
        bookingId,
        userId,
        status: newStatus,
        error,
      });
    }

    return null;
  }
);