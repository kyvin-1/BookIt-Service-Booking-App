import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminBookingsScreen extends StatelessWidget {
  const AdminBookingsScreen({super.key});

  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);
  static const Color lightGreen = Color(0xFFE9F7EF);

  // =========================================================
  // UPDATE BOOKING STATUS
  // =========================================================

          static Future<void> _updateStatus(
            BuildContext context,
            String bookingId,
            String status,
          ) async {
            try {
              // =======================================================
              // 1. GET BOOKING DATA FIRST
              // =======================================================

              final bookingDoc = await _firestore
                  .collection('bookings')
                  .doc(bookingId)
                  .get();

              if (!bookingDoc.exists) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Booking not found.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );

                return;
              }

              final bookingData = bookingDoc.data();

              if (bookingData == null) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Booking data is unavailable.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );

                return;
              }

              // =======================================================
              // 2. GET CUSTOMER ID
              // =======================================================

              final userId = bookingData['userId'];

              if (userId == null || userId.toString().isEmpty) {
                if (!context.mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Customer ID is missing from this booking.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ),
                );

                return;
              }

              // =======================================================
              // 3. UPDATE BOOKING STATUS
              // =======================================================

              await _firestore
                  .collection('bookings')
                  .doc(bookingId)
                  .update({
                'status': status,
              });

              // =======================================================
              // 4. CREATE CUSTOMER NOTIFICATION
              // =======================================================

              final providerName =
                  bookingData['providerName']?.toString() ??
                      'your service provider';

              final service =
                  bookingData['service']?.toString() ??
                      'your service';

              String title;
              String body;

              switch (status.toLowerCase()) {
                case 'confirmed':
                  title = 'Booking Confirmed';
                  body =
                      'Your $service booking with $providerName has been confirmed.';
                  break;

                case 'completed':
                  title = 'Booking Completed';
                  body =
                      'Your $service booking with $providerName has been completed.';
                  break;

                case 'cancelled':
                  title = 'Booking Cancelled';
                  body =
                      'Your $service booking with $providerName has been cancelled.';
                  break;

                default:
                  title = 'Booking Updated';
                  body =
                      'Your $service booking with $providerName is now ${_statusLabel(status)}.';
              }

              await _firestore.collection('notifications').add({
                'userId': userId.toString(),
                'title': title,
                'body': body,
                'type': 'booking',
                'bookingId': bookingId,
                'status': status,
                'isRead': false,
                'createdAt': FieldValue.serverTimestamp(),
              });

              // =======================================================
              // 5. SUCCESS MESSAGE
              // =======================================================

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Booking marked as ${_statusLabel(status)}.',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: primaryGreen,
                ),
              );
            } catch (e) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Failed to update booking: $e',
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

  // =========================================================
  // STATUS HELPERS
  // =========================================================

  static Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Colors.green.shade700;

      case 'completed':
        return Colors.blue.shade700;

      case 'cancelled':
        return Colors.red.shade700;

      default:
        return Colors.orange.shade700;
    }
  }

  static IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return Icons.check_circle_outline;

      case 'completed':
        return Icons.done_all;

      case 'cancelled':
        return Icons.cancel_outlined;

      default:
        return Icons.schedule;
    }
  }

  static String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
        return 'Confirmed';

      case 'completed':
        return 'Completed';

      case 'cancelled':
        return 'Cancelled';

      default:
        return 'Pending';
    }
  }

  // =========================================================
  // FORMAT TIME
  // =========================================================

  static String _formatTime(DateTime date) {
    int hour = date.hour;

    final minute = date.minute.toString().padLeft(2, '0');

    final period = hour >= 12 ? 'PM' : 'AM';

    if (hour == 0) {
      hour = 12;
    } else if (hour > 12) {
      hour -= 12;
    }

    return '$hour:$minute $period';
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  static String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'No date available';
    }

    final date = timestamp.toDate();

    return '${date.month}/${date.day}/${date.year}';
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: darkText,
            size: 20,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Booking Management',
              style: TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Manage customer appointments',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('bookings')
            .orderBy('dateTime')
            .snapshots(),
        builder: (context, snapshot) {
          // =================================================
          // ERROR
          // =================================================

          if (snapshot.hasError) {
            return _buildErrorState(
              context,
              snapshot.error.toString(),
            );
          }

          // =================================================
          // LOADING
          // =================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          final bookings = snapshot.data?.docs ?? [];

          // =================================================
          // EMPTY
          // =================================================

          if (bookings.isEmpty) {
            return _buildEmptyState();
          }

          // =================================================
          // MAIN CONTENT
          // =================================================

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              30,
            ),
            children: [
              _buildSummary(bookings),

              const SizedBox(height: 20),

              const Text(
                'All Bookings',
                style: TextStyle(
                  color: darkText,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                '${bookings.length} total booking${bookings.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: secondaryText,
                  fontSize: 13,
                ),
              ),

              const SizedBox(height: 14),

              ...bookings.map(
                (doc) => _buildBookingCard(
                  context,
                  doc,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // SUMMARY
  // =========================================================

  Widget _buildSummary(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> bookings,
  ) {
    int pending = 0;
    int confirmed = 0;
    int completed = 0;
    int cancelled = 0;

    for (final booking in bookings) {
      final status = booking.data()['status'] ?? 'pending';

      switch (status) {
        case 'pending':
          pending++;
          break;

        case 'confirmed':
          confirmed++;
          break;

        case 'completed':
          completed++;
          break;

        case 'cancelled':
          cancelled++;
          break;
      }
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.65,
      children: [
        _buildSummaryCard(
          title: 'Pending',
          value: pending,
          icon: Icons.schedule,
          color: Colors.orange.shade700,
          background: Colors.orange.shade50,
        ),
        _buildSummaryCard(
          title: 'Confirmed',
          value: confirmed,
          icon: Icons.check_circle_outline,
          color: Colors.green.shade700,
          background: Colors.green.shade50,
        ),
        _buildSummaryCard(
          title: 'Completed',
          value: completed,
          icon: Icons.done_all,
          color: Colors.blue.shade700,
          background: Colors.blue.shade50,
        ),
        _buildSummaryCard(
          title: 'Cancelled',
          value: cancelled,
          icon: Icons.cancel_outlined,
          color: Colors.red.shade700,
          background: Colors.red.shade50,
        ),
      ],
    );
  }

  // =========================================================
  // SUMMARY CARD
  // =========================================================

  Widget _buildSummaryCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required Color background,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              icon,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$value',
                  style: TextStyle(
                    color: color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: const TextStyle(
                    color: secondaryText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BOOKING CARD
  // =========================================================

  Widget _buildBookingCard(
    BuildContext context,
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final providerName =
        data['providerName'] ?? 'Unknown Provider';

    final service =
        data['service'] ?? 'Unknown Service';

    final userEmail =
        data['userEmail'] ?? 'Customer email unavailable';

    final status =
        data['status'] ?? 'pending';

    final timestamp =
        data['dateTime'] is Timestamp
            ? data['dateTime'] as Timestamp
            : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(alpha: 0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // =================================================
            // TOP ROW
            // =================================================

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: lightGreen,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.event_available,
                    color: primaryGreen,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        providerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        service,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: secondaryText,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                _buildStatusBadge(status),
              ],
            ),

            const SizedBox(height: 16),

            // =================================================
            // CUSTOMER
            // =================================================

            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Customer',
              value: userEmail,
            ),

            const SizedBox(height: 10),

            // =================================================
            // DATE
            // =================================================

            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(timestamp),
            ),

            const SizedBox(height: 10),

            // =================================================
            // TIME
            // =================================================

            _buildInfoRow(
              icon: Icons.access_time,
              label: 'Time',
              value: timestamp == null
                  ? 'No time available'
                  : _formatTime(timestamp.toDate()),
            ),

            // =================================================
            // ACTIONS
            // =================================================

            if (status != 'completed' &&
                status != 'cancelled') ...[
              const SizedBox(height: 16),

              const Divider(
                height: 1,
                color: Color(0xFFE9EEEB),
              ),

              const SizedBox(height: 14),

              _buildActionButtons(
                context,
                doc.id,
                status,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // STATUS BADGE
  // =========================================================

  Widget _buildStatusBadge(String status) {
    final color = _statusColor(status);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon(status),
            size: 15,
            color: color,
          ),

          const SizedBox(width: 5),

          Text(
            _statusLabel(status),
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // INFO ROW
  // =========================================================

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: secondaryText,
        ),

        const SizedBox(width: 10),

        SizedBox(
          width: 62,
          child: Text(
            label,
            style: const TextStyle(
              color: secondaryText,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: darkText,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // =========================================================
  // ACTION BUTTONS
  // =========================================================

  Widget _buildActionButtons(
    BuildContext context,
    String bookingId,
    String status,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        // CONFIRM
        if (status == 'pending')
          ElevatedButton.icon(
            onPressed: () {
              _updateStatus(
                context,
                bookingId,
                'confirmed',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryGreen,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.check,
              size: 18,
            ),
            label: const Text(
              'Confirm',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // COMPLETE
        if (status == 'confirmed')
          ElevatedButton.icon(
            onPressed: () {
              _updateStatus(
                context,
                bookingId,
                'completed',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.done_all,
              size: 18,
            ),
            label: const Text(
              'Complete',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

        // CANCEL
        if (status == 'pending' ||
            status == 'confirmed')
          OutlinedButton.icon(
            onPressed: () {
              _showCancelConfirmation(
                context,
                bookingId,
              );
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red.shade700,
              side: BorderSide(
                color: Colors.red.shade200,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 11,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(
              Icons.close,
              size: 18,
            ),
            label: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  // =========================================================
  // CANCEL CONFIRMATION
  // =========================================================

  static void _showCancelConfirmation(
    BuildContext context,
    String bookingId,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Cancel Booking?',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'Are you sure you want to cancel this booking?',
            style: TextStyle(
              color: secondaryText,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Keep Booking',
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                _updateStatus(
                  context,
                  bookingId,
                  'cancelled',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Cancel Booking',
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_outlined,
                color: primaryGreen,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Bookings Yet',
              style: TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Customer bookings will appear here once they are created.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState(
    BuildContext context,
    String error,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red.shade700,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to Load Bookings',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Something went wrong while loading the bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 14),

            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.red.shade700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}