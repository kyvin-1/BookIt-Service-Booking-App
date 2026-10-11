import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'admin_account_settings_screen.dart';
import 'admin_providers_screen.dart';
import 'admin_bookings_screen.dart';
import 'admin_reviews_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);
  static const Color lightGreen = Color(0xFFE9F7EF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // =========================================================
      // APP BAR
      // =========================================================

      appBar: AppBar(
        backgroundColor: backgroundColor,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
            color: darkText,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Admin Account',
            icon: const Icon(Icons.account_circle_outlined),
            onSelected: (value) async {
              if (value == 'settings') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const AdminAccountSettingsScreen(),
                  ),
                );
              }

              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) {
                    return AlertDialog(
                      title: const Text('Logout'),
                      content: const Text(
                        'Are you sure you want to logout?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              false,
                            );
                          },
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () {
                            Navigator.pop(
                              dialogContext,
                              true,
                            );
                          },
                          child: const Text('Logout'),
                        ),
                      ],
                    );
                  },
                );

                if (shouldLogout == true) {
                  await AuthService().logout();
                }
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings_outlined),
                    SizedBox(width: 12),
                    Text('Account Settings'),
                  ],
                ),
              ),
              PopupMenuDivider(),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 12),
                    Text('Logout'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),

      // =========================================================
      // BODY
      // =========================================================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .snapshots(),

        builder: (context, snapshot) {
          // =====================================================
          // LOADING
          // =====================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          // =====================================================
          // ERROR
          // =====================================================

          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          final bookings = snapshot.data?.docs ?? [];

          // =====================================================
          // BOOKING STATUS COUNTS
          // =====================================================

          int pending = 0;
          int confirmed = 0;
          int completed = 0;
          int cancelled = 0;

          // =====================================================
          // TODAY'S BOOKING COUNT
          // =====================================================

          final now = DateTime.now();

          final todayStart = DateTime(
            now.year,
            now.month,
            now.day,
          );

          final tomorrowStart = todayStart.add(
            const Duration(days: 1),
          );

          int todayBookings = 0;

          // =====================================================
          // LOOP THROUGH BOOKINGS
          // =====================================================

          for (final booking in bookings) {
            final data = booking.data();

            final status = (data['status'] ?? 'pending')
                .toString()
                .toLowerCase();

            // -----------------------------------------------
            // STATUS COUNT
            // -----------------------------------------------

            switch (status) {
              case 'confirmed':
                confirmed++;
                break;

              case 'completed':
                completed++;
                break;

              case 'cancelled':
                cancelled++;
                break;

              default:
                pending++;
            }

            // -----------------------------------------------
            // TODAY'S BOOKING COUNT
            // -----------------------------------------------

            final dateTime = data['dateTime'];

            if (dateTime is Timestamp) {
              final bookingDate =
                  dateTime.toDate().toLocal();

              final isToday =
                  !bookingDate.isBefore(todayStart) &&
                  bookingDate.isBefore(tomorrowStart);

              if (isToday && status != 'cancelled') {
                todayBookings++;
              }
            }
          }

          // =====================================================
          // DASHBOARD CONTENT
          // =====================================================

          return RefreshIndicator(
            color: primaryGreen,

            onRefresh: () async {
              await Future.delayed(
                const Duration(milliseconds: 500),
              );
            },

            child: ListView(
              physics:
                  const AlwaysScrollableScrollPhysics(),

              padding: const EdgeInsets.fromLTRB(
                16,
                10,
                16,
                30,
              ),

              children: [
                // =================================================
                // WELCOME HEADER
                // =================================================

                _buildWelcomeHeader(),

                const SizedBox(height: 26),

                // =================================================
                // OVERVIEW
                // =================================================

                const Text(
                  'Overview',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Monitor your BookIt booking activity.',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 16),

                // =================================================
                // TOTAL BOOKINGS
                // =================================================

                _buildMainStatCard(
                  title: 'Total Bookings',
                  value: bookings.length.toString(),
                  icon: Icons.calendar_month_rounded,
                ),

                const SizedBox(height: 12),

                // =================================================
                // TODAY'S BOOKINGS
                // =================================================

                _buildMainStatCard(
                  title: "Today's Bookings",
                  value: todayBookings.toString(),
                  icon: Icons.today_rounded,
                ),

                const SizedBox(height: 12),

                // =================================================
                // PENDING + CONFIRMED
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Pending',
                        value: pending,
                        icon: Icons.schedule_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Confirmed',
                        value: confirmed,
                        icon:
                            Icons.check_circle_outline_rounded,
                        color: primaryGreen,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // =================================================
                // COMPLETED + CANCELLED
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        title: 'Completed',
                        value: completed,
                        icon: Icons.task_alt_rounded,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        title: 'Cancelled',
                        value: cancelled,
                        icon: Icons.cancel_outlined,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // =================================================
                // QUICK ACTIONS
                // =================================================

                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: darkText,
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Manage your BookIt platform.',
                  style: TextStyle(
                    fontSize: 13,
                    color: secondaryText,
                  ),
                ),

                const SizedBox(height: 16),

                // Manage Bookings
                _buildActionButton(
                  context: context,
                  title: 'Manage Bookings',
                  subtitle:
                      'View and update customer bookings',
                  icon: Icons.calendar_month_rounded,
                  color: primaryGreen,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminBookingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Manage Providers
                _buildActionButton(
                  context: context,
                  title: 'Manage Providers',
                  subtitle:
                      'Add and manage service providers',
                  icon: Icons.business_rounded,
                  color: Colors.blue,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminProvidersScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // Manage Reviews
                _buildActionButton(
                  context: context,
                  title: 'Manage Reviews',
                  subtitle:
                      'View and manage customer reviews',
                  icon: Icons.rate_review_rounded,
                  color: Colors.orange,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const AdminReviewsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 30),

                // =================================================
                // RECENT BOOKINGS
                // =================================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Bookings',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: darkText,
                      ),
                    ),

                    if (bookings.isNotEmpty)
                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${bookings.length} total',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 14),

                if (bookings.isEmpty)
                  _buildNoBookings()
                else
                  ...bookings.take(5).map(
                    (booking) =>
                        _buildRecentBooking(booking),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =============================================================
  // WELCOME HEADER
  // =============================================================

  Widget _buildWelcomeHeader() {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF147A4A),
            Color(0xFF35AD70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(22),

        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(
              alpha: 0.18,
            ),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,

            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius:
                  BorderRadius.circular(17),
            ),

            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 31,
            ),
          ),

          const SizedBox(width: 15),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, Admin 👋',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Manage your BookIt service platform.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // MAIN STAT CARD
  // =============================================================

  Widget _buildMainStatCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF147A4A),
            Color(0xFF35AD70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(20),

        boxShadow: [
          BoxShadow(
            color: primaryGreen.withValues(
              alpha: 0.16,
            ),
            blurRadius: 15,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,

            decoration: BoxDecoration(
              color: Colors.white.withValues(
                alpha: 0.18,
              ),
              borderRadius:
                  BorderRadius.circular(16),
            ),

            child: Icon(
              icon,
              color: Colors.white,
              size: 29,
            ),
          ),

          const SizedBox(width: 16),

          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =============================================================
  // SMALL STAT CARD
  // =============================================================

  Widget _buildStatCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,

                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(11),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),

              const Spacer(),

              Text(
                value.toString(),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: darkText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ACTION BUTTON
  // =============================================================

  Widget _buildActionButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),

        child: Container(
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,

                decoration: BoxDecoration(
                  color: color.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(15),
                ),

                child: Icon(
                  icon,
                  color: color,
                  size: 25,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: secondaryText,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                width: 34,
                height: 34,

                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),

                child: const Icon(
                  Icons.chevron_right_rounded,
                  size: 21,
                  color: secondaryText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =============================================================
  // RECENT BOOKING
  // =============================================================

  Widget _buildRecentBooking(
    QueryDocumentSnapshot<Map<String, dynamic>>
        booking,
  ) {
    final data = booking.data();

    final providerName =
        (data['providerName'] ??
                'Unknown Provider')
            .toString();

    final service =
        (data['service'] ?? 'Service')
            .toString();

    final status =
        (data['status'] ?? 'pending')
            .toString()
            .toLowerCase();

    final userEmail =
        (data['userEmail'] ??
                'Unknown Customer')
            .toString();

    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'confirmed':
        statusColor = primaryGreen;
        statusIcon =
            Icons.check_circle_outline_rounded;
        break;

      case 'completed':
        statusColor = Colors.blue;
        statusIcon =
            Icons.task_alt_rounded;
        break;

      case 'cancelled':
        statusColor = Colors.red;
        statusIcon =
            Icons.cancel_outlined;
        break;

      default:
        statusColor = Colors.orange;
        statusIcon =
            Icons.schedule_rounded;
    }

    final displayStatus = status.isEmpty
        ? 'Pending'
        : status[0].toUpperCase() +
            status.substring(1);

    String dateText = '';

    final dateTime = data['dateTime'];

    if (dateTime is Timestamp) {
      final date = dateTime.toDate().toLocal();

      final hour = date.hour > 12
          ? date.hour - 12
          : date.hour == 0
              ? 12
              : date.hour;

      final minute =
          date.minute.toString().padLeft(
                2,
                '0',
              );

      final period =
          date.hour >= 12 ? 'PM' : 'AM';

      dateText =
          '${date.month}/${date.day}/${date.year} '
          '$hour:$minute $period';
    }

    return Container(
      margin: const EdgeInsets.only(
        bottom: 12,
      ),

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.02,
            ),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,

                decoration: BoxDecoration(
                  color: lightGreen,
                  borderRadius:
                      BorderRadius.circular(13),
                ),

                child: const Icon(
                  Icons.business_outlined,
                  color: primaryGreen,
                  size: 21,
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
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w700,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 3),

                    Text(
                      service,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: secondaryText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 6,
                ),

                decoration: BoxDecoration(
                  color: statusColor.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(20),
                ),

                child: Row(
                  mainAxisSize:
                      MainAxisSize.min,
                  children: [
                    Icon(
                      statusIcon,
                      size: 13,
                      color: statusColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      displayStatus,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight:
                            FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              const Icon(
                Icons.person_outline_rounded,
                size: 17,
                color: secondaryText,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  userEmail,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ),
            ],
          ),

          if (dateText.isNotEmpty) ...[
            const SizedBox(height: 8),

            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 17,
                  color: secondaryText,
                ),

                const SizedBox(width: 7),

                Text(
                  dateText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: secondaryText,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // =============================================================
  // NO BOOKINGS
  // =============================================================

  Widget _buildNoBookings() {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 25,
        vertical: 40,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),

      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,

            decoration: BoxDecoration(
              color: lightGreen,
              shape: BoxShape.circle,
            ),

            child: const Icon(
              Icons.calendar_month_outlined,
              size: 36,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            'No bookings yet',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: darkText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'New customer bookings will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 82,
              height: 82,

              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),

              child: Icon(
                Icons.error_outline_rounded,
                size: 42,
                color: Colors.red.shade600,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Something went wrong',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: darkText,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: secondaryText,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}