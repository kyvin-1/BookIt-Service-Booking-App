import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminAccountSettingsScreen extends StatefulWidget {
  const AdminAccountSettingsScreen({super.key});

  @override
  State<AdminAccountSettingsScreen> createState() =>
      _AdminAccountSettingsScreenState();
}

class _AdminAccountSettingsScreenState
    extends State<AdminAccountSettingsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool bookingNotifications = true;
  bool reviewNotifications = true;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    final String name =
        user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'Admin';

    final String email = user?.email ?? 'No email available';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F7),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9F7),
        foregroundColor: const Color(0xFF17231D),
        elevation: 0,
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 21,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
        children: [
          // PROFILE
          _sectionTitle('Profile'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE9F7EF),
                    borderRadius: BorderRadius.circular(17),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings_outlined,
                    color: Color(0xFF1D9B61),
                    size: 31,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF17231D),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF69736D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // SECURITY
          _sectionTitle('Security'),
          const SizedBox(height: 10),

          _settingsCard(
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: () {
              _showChangePasswordDialog(context);
            },
          ),

          const SizedBox(height: 10),

          _settingsCard(
            icon: Icons.verified_user_outlined,
            title: 'Email Verification',
            subtitle: user?.emailVerified == true
                ? 'Your email is verified'
                : 'Your email is not verified',
            trailing: Icon(
              user?.emailVerified == true
                  ? Icons.check_circle
                  : Icons.warning_amber_rounded,
              color: user?.emailVerified == true
                  ? const Color(0xFF1D9B61)
                  : Colors.orange,
            ),
            onTap: () {
              _showVerificationStatus(context, user);
            },
          ),

          const SizedBox(height: 28),

          // NOTIFICATIONS
          _sectionTitle('Notifications'),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  value: bookingNotifications,
                  activeThumbColor: const Color(0xFF1D9B61),
                  title: const Text(
                    'Booking Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17231D),
                    ),
                  ),
                  subtitle: const Text(
                    'Receive notifications about bookings',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF69736D),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      bookingNotifications = value;
                    });
                  },
                ),
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                SwitchListTile(
                  value: reviewNotifications,
                  activeThumbColor: const Color(0xFF1D9B61),
                  title: const Text(
                    'Review Notifications',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF17231D),
                    ),
                  ),
                  subtitle: const Text(
                    'Receive notifications about customer reviews',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF69736D),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      reviewNotifications = value;
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // ABOUT
          _sectionTitle('About'),
          const SizedBox(height: 10),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: Colors.grey.shade200,
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: Color(0xFF1D9B61),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'BookIt',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF17231D),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Service Booking App',
                  style: TextStyle(
                    color: Color(0xFF69736D),
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    color: Color(0xFF69736D),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: Color(0xFF17231D),
      ),
    );
  }

  Widget _settingsCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
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
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE9F7EF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF1D9B61),
                  size: 23,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF17231D),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF69736D),
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xFF69736D),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showChangePasswordDialog(
    BuildContext context,
  ) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: TextField(
            controller: controller,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'New Password',
              hintText: 'Enter new password',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final password = controller.text.trim();

                if (password.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password must be at least 6 characters.',
                      ),
                    ),
                  );
                  return;
                }

                try {
                  await _auth.currentUser?.updatePassword(password);

                  if (!context.mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Password updated successfully.',
                      ),
                    ),
                  );
                } on FirebaseAuthException catch (e) {
                  if (!context.mounted) return;

                  Navigator.pop(dialogContext);

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        e.message ??
                            'Unable to change password.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  void _showVerificationStatus(
    BuildContext context,
    User? user,
  ) {
    final verified = user?.emailVerified == true;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Email Verification'),
          content: Text(
            verified
                ? 'Your admin email is verified.'
                : 'Your admin email is not verified yet.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}