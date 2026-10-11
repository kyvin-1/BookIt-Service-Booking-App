import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/notification_service.dart';
import '../booking/my_bookings_screen.dart';
import '../booking/booking_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // =========================================================
  // COLORS
  // =========================================================

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color lightBackground = Color(0xFFF7FAF8);

  // =========================================================
  // FILTER
  // =========================================================

  bool _showUnreadOnly = false;

  // =========================================================
  // NOTIFICATION STREAM
  // =========================================================

  Stream<QuerySnapshot<Map<String, dynamic>>>
      _notificationStream(String userId) {
    return FirebaseFirestore.instance
        .collection('notifications')
        .where(
          'userId',
          isEqualTo: userId,
        )
        .snapshots();
  }

  // =========================================================
  // MARK ALL AS READ
  // =========================================================

  Future<void> _markAllAsRead(
    String userId,
  ) async {
    try {
      await NotificationService.markAllAsRead(userId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'All notifications marked as read.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to mark notifications as read.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // DELETE NOTIFICATION
  // =========================================================

  Future<void> _deleteNotification(
    String notificationId,
  ) async {
    try {
      await NotificationService.deleteNotification(
        notificationId,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete notification.',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =========================================================
  // MARK AS READ
  // =========================================================

  Future<void> _markAsRead(
    String notificationId,
  ) async {
    try {
      await NotificationService.markAsRead(
        notificationId,
      );
    } catch (e) {
      debugPrint(
        'Failed to mark notification as read: $e',
      );
    }
  }

  // =========================================================
  // OPEN NOTIFICATION
  // =========================================================

  Future<void> _openNotification(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) async {
    final data = document.data();

    final notificationId = document.id;

    final type =
        data['type']?.toString() ?? 'general';

    final bookingId =
        data['bookingId']?.toString();

    // -------------------------------------------------------
    // MARK AS READ
    // -------------------------------------------------------

    if (data['isRead'] != true) {
      await _markAsRead(notificationId);
    }

    if (!mounted) return;

    // -------------------------------------------------------
    // BOOKING NOTIFICATION
    // -------------------------------------------------------

    if (type == 'booking') {
      // -----------------------------------------------------
      // OPEN EXACT BOOKING
      // -----------------------------------------------------

      if (bookingId != null &&
          bookingId.isNotEmpty) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                BookingDetailsScreen(
              bookingId: bookingId,
            ),
          ),
        );

        return;
      }

      // -----------------------------------------------------
      // FALLBACK FOR OLD NOTIFICATIONS
      // -----------------------------------------------------

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const MyBookingsScreen(),
        ),
      );

      return;
    }

    // -------------------------------------------------------
    // GENERAL NOTIFICATION
    // -------------------------------------------------------

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Notification marked as read.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // =========================================================
  // NOTIFICATION ICON
  // =========================================================

  IconData _getNotificationIcon(
    String type,
    String status,
  ) {
    if (type == 'booking') {
      switch (status) {
        case 'confirmed':
          return Icons.check_circle_outline;

        case 'cancelled':
          return Icons.cancel_outlined;

        case 'completed':
          return Icons.task_alt;

        case 'pending':
          return Icons.schedule;

        default:
          return Icons.event_note_outlined;
      }
    }

    return Icons.notifications_none;
  }

  // =========================================================
  // NOTIFICATION COLOR
  // =========================================================

  Color _getNotificationColor(
    String status,
  ) {
    switch (status) {
      case 'confirmed':
        return Colors.green;

      case 'cancelled':
        return Colors.red;

      case 'completed':
        return Colors.blue;

      case 'pending':
        return Colors.orange;

      default:
        return primaryGreen;
    }
  }

  // =========================================================
  // STATUS LABEL
  // =========================================================

  String _getStatusLabel(
    String status,
  ) {
    switch (status) {
      case 'confirmed':
        return 'Confirmed';

      case 'cancelled':
        return 'Cancelled';

      case 'completed':
        return 'Completed';

      case 'pending':
        return 'Pending';

      default:
        return 'Booking';
    }
  }

  // =========================================================
  // TIME FORMAT
  // =========================================================

  String _formatNotificationTime(
    dynamic timestamp,
  ) {
    if (timestamp is! Timestamp) {
      return 'Just now';
    }

    final dateTime = timestamp.toDate();
    final now = DateTime.now();

    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;

      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    }

    if (difference.inHours < 24) {
      final hours = difference.inHours;

      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
  }

  // =========================================================
  // DELETE CONFIRMATION
  // =========================================================

  Future<void> _confirmDelete(
    String notificationId,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            'Delete Notification',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          content: const Text(
            'Are you sure you want to delete this notification?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text(
                'Cancel',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteNotification(notificationId);
  }

  // =========================================================
  // FILTER BUTTON
  // =========================================================

  Widget _buildFilterButton({
    required String label,
    required int count,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(
          milliseconds: 180,
        ),
        padding: const EdgeInsets.symmetric(
          vertical: 11,
          horizontal: 12,
        ),
        decoration: BoxDecoration(
          color: selected
              ? primaryGreen.withValues(
                  alpha: 0.10,
                )
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? primaryGreen
                : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected
                    ? primaryGreen
                    : secondaryText,
              ),
            ),
            const SizedBox(width: 7),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 7,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: selected
                    ? primaryGreen
                    : Colors.grey.shade100,
                borderRadius:
                    BorderRadius.circular(20),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: selected
                      ? Colors.white
                      : secondaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NOTIFICATION FILTER
  // =========================================================

  Widget _buildNotificationFilter(
    int totalCount,
    int unreadCount,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        16,
        14,
        16,
        12,
      ),
      color: Colors.white,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$totalCount notification${totalCount == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: darkText,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: secondaryText,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$unreadCount unread',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: unreadCount > 0
                      ? primaryGreen
                      : secondaryText,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  label: 'All',
                  count: totalCount,
                  selected: !_showUnreadOnly,
                  onTap: () {
                    setState(() {
                      _showUnreadOnly = false;
                    });
                  },
                ),
              ),

              const SizedBox(width: 10),

              Expanded(
                child: _buildFilterButton(
                  label: 'Unread',
                  count: unreadCount,
                  selected: _showUnreadOnly,
                  onTap: () {
                    setState(() {
                      _showUnreadOnly = true;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 32,
        ),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 44,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Notifications Yet',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Your booking updates and other important notifications will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: secondaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NO UNREAD STATE
  // =========================================================

  Widget _buildNoUnreadState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: primaryGreen.withValues(
                  alpha: 0.10,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.mark_email_read_outlined,
                size: 40,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'No Unread Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'You are all caught up!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryText,
              ),
            ),

            const SizedBox(height: 18),

            OutlinedButton(
              onPressed: () {
                setState(() {
                  _showUnreadOnly = false;
                });
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: primaryGreen,
                side: const BorderSide(
                  color: primaryGreen,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'View All',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // NOTIFICATION CARD
  // =========================================================

  Widget _buildNotificationCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final String title =
        data['title']?.toString() ??
            'BookIt Notification';

    final String body =
        data['body']?.toString() ??
            '';

    final String type =
        data['type']?.toString() ??
            'general';

    final String status =
        data['status']?.toString() ??
            '';

    final bool isRead =
        data['isRead'] == true;

    final iconColor =
        _getNotificationColor(status);

    final icon =
        _getNotificationIcon(
          type,
          status,
        );

    final createdAt =
        data['createdAt'];

    return Dismissible(
      key: Key(document.id),

      direction:
          DismissDirection.endToStart,

      confirmDismiss: (direction) async {
        await _confirmDelete(
          document.id,
        );

        return false;
      },

      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),
        padding: const EdgeInsets.only(
          right: 24,
        ),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
              BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),

      child: InkWell(
        borderRadius:
            BorderRadius.circular(16),

        onTap: () {
          _openNotification(
            document,
          );
        },

        child: Container(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : primaryGreen.withValues(
                    alpha: 0.06,
                  ),

            borderRadius:
                BorderRadius.circular(16),

            border: Border.all(
              color: isRead
                  ? Colors.grey.shade200
                  : primaryGreen.withValues(
                      alpha: 0.20,
                    ),
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ------------------------------------------------
              // ICON
              // ------------------------------------------------

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: iconColor.withValues(
                    alpha: 0.10,
                  ),
                  shape: BoxShape.circle,
                ),

                child: Icon(
                  icon,
                  color: iconColor,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              // ------------------------------------------------
              // CONTENT
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.w700,
                              color: darkText,
                            ),
                          ),
                        ),

                        // ------------------------------------------------
                        // UNREAD DOT
                        // ------------------------------------------------

                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            margin:
                                const EdgeInsets.only(
                              left: 8,
                              top: 5,
                            ),
                            decoration:
                                const BoxDecoration(
                              color: primaryGreen,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    Text(
                      body,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: secondaryText,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Row(
                      children: [
                        if (status.isNotEmpty) ...[
                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),

                            decoration: BoxDecoration(
                              color: iconColor
                                  .withValues(
                                alpha: 0.10,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                20,
                              ),
                            ),

                            child: Text(
                              _getStatusLabel(
                                status,
                              ),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w600,
                                color: iconColor,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),
                        ],

                        Flexible(
                          child: Text(
                            _formatNotificationTime(
                              createdAt,
                            ),
                            overflow:
                                TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              color:
                                  secondaryText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    // -------------------------------------------------------
    // NO USER
    // -------------------------------------------------------

    if (user == null) {
      return Scaffold(
        backgroundColor:
            lightBackground,

        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const Text(
            'Notifications',
          ),
        ),

        body: const Center(
          child: Text(
            'Please log in to view your notifications.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          lightBackground,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor:
            Colors.transparent,
        elevation: 0,

        centerTitle: false,

        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 22,
            fontWeight:
                FontWeight.w700,
            color: darkText,
          ),
        ),

        actions: [
          StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: _notificationStream(
              user.uid,
            ),

            builder: (
              context,
              snapshot,
            ) {
              if (!snapshot.hasData) {
                return const SizedBox.shrink();
              }

              final documents =
                  snapshot.data!.docs;

              final hasUnread =
                  documents.any(
                (doc) =>
                    doc.data()['isRead'] !=
                    true,
              );

              if (!hasUnread) {
                return const SizedBox.shrink();
              }

              return TextButton(
                onPressed: () {
                  _markAllAsRead(
                    user.uid,
                  );
                },

                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: primaryGreen,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 8),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: StreamBuilder<
          QuerySnapshot<
              Map<String, dynamic>>>(
        stream: _notificationStream(
          user.uid,
        ),

        builder: (
          context,
          snapshot,
        ) {
          // -------------------------------------------------
          // LOADING
          // -------------------------------------------------

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          // -------------------------------------------------
          // ERROR
          // -------------------------------------------------

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                    const EdgeInsets.all(24),

                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,

                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 50,
                      color: Colors.red,
                    ),

                    const SizedBox(
                      height: 16,
                    ),

                    const Text(
                      'Something went wrong.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.w700,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(
                      height: 8,
                    ),

                    Text(
                      'Unable to load your notifications.',
                      textAlign:
                          TextAlign.center,
                      style: TextStyle(
                        color:
                            Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // -------------------------------------------------
          // DOCUMENTS
          // -------------------------------------------------

          final documents =
              snapshot.data?.docs ?? [];

          // -------------------------------------------------
          // EMPTY
          // -------------------------------------------------

          if (documents.isEmpty) {
            return _buildEmptyState();
          }

          // -------------------------------------------------
          // COUNT UNREAD
          // -------------------------------------------------

          final unreadDocuments =
              documents.where((doc) {
            return doc.data()['isRead'] !=
                true;
          }).toList();

          final unreadCount =
              unreadDocuments.length;

          // -------------------------------------------------
          // SORT LOCALLY
          // -------------------------------------------------
          //
          // We intentionally sort locally instead of
          // using orderBy() so we don't need a
          // composite Firestore index.
          //

          final sortedDocuments =
              [...documents];

          sortedDocuments.sort(
            (a, b) {
              final aData = a.data();
              final bData = b.data();

              final aTimestamp =
                  aData['createdAt'];

              final bTimestamp =
                  bData['createdAt'];

              if (aTimestamp is Timestamp &&
                  bTimestamp is Timestamp) {
                return bTimestamp.compareTo(
                  aTimestamp,
                );
              }

              if (aTimestamp is Timestamp) {
                return -1;
              }

              if (bTimestamp is Timestamp) {
                return 1;
              }

              return 0;
            },
          );

          // -------------------------------------------------
          // APPLY FILTER
          // -------------------------------------------------

          final filteredDocuments =
              _showUnreadOnly
                  ? sortedDocuments
                      .where((doc) {
                      return doc.data()[
                              'isRead'] !=
                          true;
                    }).toList()
                  : sortedDocuments;

          // -------------------------------------------------
          // MAIN CONTENT
          // -------------------------------------------------

          return Column(
            children: [
              // ------------------------------------------------
              // FILTER HEADER
              // ------------------------------------------------

              _buildNotificationFilter(
                documents.length,
                unreadCount,
              ),

              // ------------------------------------------------
              // LIST / EMPTY FILTER STATE
              // ------------------------------------------------

              Expanded(
                child:
                    filteredDocuments.isEmpty
                        ? _buildNoUnreadState()
                        : ListView.builder(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              16,
                              16,
                              16,
                              30,
                            ),

                            itemCount:
                                filteredDocuments
                                    .length,

                            itemBuilder:
                                (
                              context,
                              index,
                            ) {
                              return _buildNotificationCard(
                                filteredDocuments[
                                    index],
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}