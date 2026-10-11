import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminProvidersScreen extends StatelessWidget {
  const AdminProvidersScreen({super.key});

  static const String _collection = 'providers';

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);
  static const Color backgroundColor = Color(0xFFF5F9F7);
  static const Color lightGreen = Color(0xFFE9F7EF);

  // =========================================================
  // SAMPLE PROVIDERS
  // =========================================================

  static const List<Map<String, dynamic>> _sampleProviders = [
    {
      'id': 'sample_glow_beauty_salon',
      'name': 'Glow Beauty Salon',
      'category': 'Hair & Beauty',
      'description':
          'Professional beauty and hair care services for everyday and special occasions.',
      'price': 300.0,
      'rating': 4.8,
      'imageUrl': '',
      'servicesOffered': [
        'Haircut',
        'Hair Color',
        'Manicure',
        'Pedicure',
      ],
    },
    {
      'id': 'sample_cleanpro_home_services',
      'name': 'CleanPro Home Services',
      'category': 'Home Cleaning',
      'description':
          'Reliable home cleaning services for apartments, houses, and small offices.',
      'price': 500.0,
      'rating': 4.7,
      'imageUrl': '',
      'servicesOffered': [
        'House Cleaning',
        'Deep Cleaning',
        'Kitchen Cleaning',
        'Bathroom Cleaning',
      ],
    },
    {
      'id': 'sample_fixright_services',
      'name': 'FixRight Services',
      'category': 'Repair & Maintenance',
      'description':
          'Professional repair and maintenance services for homes and appliances.',
      'price': 450.0,
      'rating': 4.6,
      'imageUrl': '',
      'servicesOffered': [
        'Plumbing',
        'Electrical Repair',
        'Appliance Repair',
        'Installation',
      ],
    },
    {
      'id': 'sample_autocare_garage',
      'name': 'AutoCare Garage',
      'category': 'Automotive',
      'description':
          'Trusted automotive services to keep your vehicle safe and road-ready.',
      'price': 600.0,
      'rating': 4.8,
      'imageUrl': '',
      'servicesOffered': [
        'Oil Change',
        'Car Wash',
        'Brake Service',
        'Basic Inspection',
      ],
    },
    {
      'id': 'sample_petcare_grooming',
      'name': 'PetCare Grooming',
      'category': 'Pet Services',
      'description':
          'Friendly and caring grooming services for dogs, cats, and other household pets.',
      'price': 350.0,
      'rating': 4.9,
      'imageUrl': '',
      'servicesOffered': [
        'Pet Grooming',
        'Bath & Grooming',
        'Nail Trimming',
        'Ear Cleaning',
      ],
    },
    {
      'id': 'sample_techfix_solutions',
      'name': 'TechFix Solutions',
      'category': 'Computer & IT',
      'description':
          'Computer and technology support for students, homes, and small businesses.',
      'price': 500.0,
      'rating': 4.7,
      'imageUrl': '',
      'servicesOffered': [
        'Laptop Repair',
        'PC Setup',
        'Software Installation',
        'Computer Troubleshooting',
      ],
    },
    {
      'id': 'sample_quickwash_laundry',
      'name': 'QuickWash Laundry',
      'category': 'Laundry',
      'description':
          'Fast and convenient laundry services for everyday clothing and household items.',
      'price': 180.0,
      'rating': 4.6,
      'imageUrl': '',
      'servicesOffered': [
        'Wash & Fold',
        'Dry Cleaning',
        'Ironing',
        'Express Laundry',
      ],
    },
    {
      'id': 'sample_fitzone_fitness',
      'name': 'FitZone Fitness',
      'category': 'Fitness',
      'description':
          'Personalized fitness services designed to help you reach your health and fitness goals.',
      'price': 700.0,
      'rating': 4.8,
      'imageUrl': '',
      'servicesOffered': [
        'Personal Training',
        'Fitness Consultation',
        'Workout Planning',
        'Weight Training',
      ],
    },
    {
      'id': 'sample_freshbite_catering',
      'name': 'FreshBite Catering',
      'category': 'Catering',
      'description':
          'Delicious catering services for birthdays, family gatherings, and special events.',
      'price': 1500.0,
      'rating': 4.7,
      'imageUrl': '',
      'servicesOffered': [
        'Birthday Catering',
        'Event Catering',
        'Party Food',
        'Buffet Setup',
      ],
    },
    {
      'id': 'sample_photopro_studio',
      'name': 'PhotoPro Studio',
      'category': 'Photography',
      'description':
          'Professional photography services for portraits, events, products, and special moments.',
      'price': 1000.0,
      'rating': 4.9,
      'imageUrl': '',
      'servicesOffered': [
        'Portrait Photography',
        'Event Photography',
        'Product Photos',
        'Photo Editing',
      ],
    },
  ];

  // =========================================================
  // ADD SAMPLE PROVIDERS
  // =========================================================

  Future<void> _addSampleProviders(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Add Sample Providers?',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: const Text(
            'This will add 10 sample service providers to your BookIt system.\n\n'
            'Existing providers will not be deleted.',
            style: TextStyle(
              color: secondaryText,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text(
                'Add Providers',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final batch = firestore.batch();

      int addedCount = 0;

      for (final provider in _sampleProviders) {
        final providerId = provider['id'].toString();

        final providerRef = firestore
            .collection(_collection)
            .doc(providerId);

        final existingDoc = await providerRef.get();

        if (!existingDoc.exists) {
          final data = Map<String, dynamic>.from(provider);

          data.remove('id');

          batch.set(
            providerRef,
            data,
          );

          addedCount++;
        }
      }

      if (addedCount > 0) {
        await batch.commit();
      }

      if (!context.mounted) return;

      if (addedCount == 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Sample providers are already added.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$addedCount sample provider${addedCount == 1 ? '' : 's'} added successfully.',
            ),
            backgroundColor: primaryGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to add sample providers: $e',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // DELETE PROVIDER
  // =========================================================

  Future<void> _deleteProvider(
    BuildContext context,
    String providerId,
    String providerName,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Provider?',
            style: TextStyle(
              color: darkText,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete "$providerName"?\n\n'
            'This action cannot be undone.',
            style: const TextStyle(
              color: secondaryText,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: secondaryText,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await FirebaseFirestore.instance
          .collection(_collection)
          .doc(providerId)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Provider deleted successfully.',
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to delete provider.',
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // PROVIDER FORM
  // =========================================================

  void _showProviderForm(
    BuildContext context, {
    DocumentSnapshot<Map<String, dynamic>>? provider,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _ProviderForm(
          provider: provider,
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,

      // =====================================================
      // APP BAR
      // =====================================================

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
              'Manage Providers',
              style: TextStyle(
                color: darkText,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Add and manage service providers',
              style: TextStyle(
                color: secondaryText,
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
      ),

      // =====================================================
      // ADD PROVIDER BUTTON
      // =====================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showProviderForm(context);
        },
        backgroundColor: primaryGreen,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Provider',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // =====================================================
      // PROVIDER LIST
      // =====================================================

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection(_collection)
            .snapshots(),

        builder: (context, snapshot) {
          // =================================================
          // LOADING
          // =================================================

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: primaryGreen,
              ),
            );
          }

          // =================================================
          // ERROR
          // =================================================

          if (snapshot.hasError) {
            return _buildErrorState(
              snapshot.error.toString(),
            );
          }

          final providers = snapshot.data?.docs ?? [];

          // =================================================
          // EMPTY
          // =================================================

          if (providers.isEmpty) {
            return _buildEmptyState(context);
          }

          // =================================================
          // PROVIDER LIST
          // =================================================

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              14,
              16,
              110,
            ),
            children: [
              _buildHeader(
                context,
                providers.length,
              ),

              const SizedBox(height: 16),

              ...providers.map(
                (provider) => _buildProviderCard(
                  context,
                  provider,
                  provider.data(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // =========================================================
  // HEADER
  // =========================================================

  Widget _buildHeader(
    BuildContext context,
    int count,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
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
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Service Providers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      '$count provider${count == 1 ? '' : 's'} registered',
                      style: TextStyle(
                        color: Colors.white.withValues(
                          alpha: 0.85,
                        ),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(
                    alpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // =================================================
          // SAMPLE PROVIDER BUTTON
          // =================================================

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                _addSampleProviders(context);
              },
              icon: const Icon(
                Icons.auto_awesome,
                size: 18,
              ),
              label: const Text(
                'Add 10 Sample Providers',
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withValues(
                    alpha: 0.45,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // PROVIDER CARD
  // =========================================================

  Widget _buildProviderCard(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> provider,
    Map<String, dynamic> data,
  ) {
    final name =
        (data['name'] ?? 'Unnamed Provider').toString();

    final category =
        (data['category'] ??
                data['specialty'] ??
                'Service Provider')
            .toString();

    final description =
        (data['description'] ?? '').toString();

    final imageUrl =
        (data['imageUrl'] ?? '').toString();

    final price =
        data['price'] ?? data['hourlyRate'] ?? 0;

    final rating =
        data['rating'] ?? 0;

    final services =
        data['servicesOffered'] is List
            ? List<String>.from(
                (data['servicesOffered'] as List)
                    .map(
                      (item) => item.toString(),
                    ),
              )
            : <String>[];

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.black.withValues(
            alpha: 0.05,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: 0.04,
            ),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                _buildProviderImage(
                  imageUrl,
                ),

                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 2,
                        overflow:
                            TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: darkText,
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: lightGreen,
                          borderRadius:
                              BorderRadius.circular(20),
                        ),
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: primaryGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 8),

                        Text(
                          description,
                          maxLines: 2,
                          overflow:
                              TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: secondaryText,
                            fontSize: 12,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 4),

                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert,
                    color: secondaryText,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(14),
                  ),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showProviderForm(
                        context,
                        provider: provider,
                      );
                    }

                    if (value == 'delete') {
                      _deleteProvider(
                        context,
                        provider.id,
                        name,
                      );
                    }
                  },
                  itemBuilder: (context) {
                    return const [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(
                              Icons.edit_outlined,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text('Edit'),
                          ],
                        ),
                      ),

                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                              size: 20,
                            ),
                            SizedBox(width: 10),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(
              height: 1,
              color: Color(0xFFE9EEEB),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                _buildInfoItem(
                  icon: Icons.star,
                  value: rating.toString(),
                  label: 'Rating',
                  iconColor:
                      Colors.amber.shade700,
                ),

                const SizedBox(width: 18),

                _buildInfoItem(
                  icon:
                      Icons.payments_outlined,
                  value: '₱$price',
                  label: 'Starting rate',
                  iconColor: primaryGreen,
                ),
              ],
            ),

            if (services.isNotEmpty) ...[
              const SizedBox(height: 12),

              Align(
                alignment:
                    Alignment.centerLeft,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: services
                      .take(3)
                      .map(
                        (service) => Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                            vertical: 6,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                Colors.grey.shade100,
                            borderRadius:
                                BorderRadius.circular(
                              20,
                            ),
                          ),
                          child: Text(
                            service,
                            style:
                                const TextStyle(
                              color:
                                  secondaryText,
                              fontSize: 10,
                              fontWeight:
                                  FontWeight.w500,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // INFO ITEM
  // =========================================================

  Widget _buildInfoItem({
    required IconData icon,
    required String value,
    required String label,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          color: iconColor,
          size: 18,
        ),

        const SizedBox(width: 6),

        Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: darkText,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: secondaryText,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // =========================================================
  // PROVIDER IMAGE
  // =========================================================

  Widget _buildProviderImage(
    String imageUrl,
  ) {
    if (imageUrl.isEmpty) {
      return Container(
        width: 78,
        height: 78,
        decoration: BoxDecoration(
          color: lightGreen,
          borderRadius:
              BorderRadius.circular(17),
        ),
        child: const Icon(
          Icons.business_outlined,
          size: 34,
          color: primaryGreen,
        ),
      );
    }

    return ClipRRect(
      borderRadius:
          BorderRadius.circular(17),
      child: Image.network(
        imageUrl,
        width: 78,
        height: 78,
        fit: BoxFit.cover,
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          return Container(
            width: 78,
            height: 78,
            color: lightGreen,
            child: const Icon(
              Icons.business_outlined,
              color: primaryGreen,
              size: 34,
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState(
    BuildContext context,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: lightGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.business_outlined,
                color: primaryGreen,
                size: 42,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No Providers Yet',
              style: TextStyle(
                color: darkText,
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Add your first service provider to start accepting bookings.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: () {
                _showProviderForm(context);
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    primaryGreen,
                foregroundColor:
                    Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              icon:
                  const Icon(Icons.add),
              label: const Text(
                'Add Provider',
                style: TextStyle(
                  fontWeight:
                      FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                _addSampleProviders(
                  context,
                );
              },
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    primaryGreen,
                side:
                    const BorderSide(
                  color: primaryGreen,
                ),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 13,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(13),
                ),
              ),
              icon: const Icon(
                Icons.auto_awesome,
              ),
              label: const Text(
                'Add 10 Sample Providers',
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
    String error,
  ) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
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
                color:
                    Colors.red.shade700,
                size: 38,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to Load Providers',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: darkText,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Something went wrong while loading service providers.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color: secondaryText,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              error,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.red.shade700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==================================================================
// PROVIDER FORM
// ==================================================================

class _ProviderForm extends StatefulWidget {
  final DocumentSnapshot<Map<String, dynamic>>?
      provider;

  const _ProviderForm({
    this.provider,
  });

  @override
  State<_ProviderForm> createState() =>
      _ProviderFormState();
}

class _ProviderFormState
    extends State<_ProviderForm> {
  static const String _collection =
      'providers';

  static const Color primaryGreen =
      Color(0xFF1D9B61);
  static const Color darkText =
      Color(0xFF17231D);
  static const Color secondaryText =
      Color(0xFF69736D);
  static const Color backgroundColor =
      Color(0xFFF5F9F7);
  static const Color lightGreen =
      Color(0xFFE9F7EF);

  final _formKey =
      GlobalKey<FormState>();

  late final TextEditingController
      _nameController;

  late final TextEditingController
      _categoryController;

  late final TextEditingController
      _descriptionController;

  late final TextEditingController
      _priceController;

  late final TextEditingController
      _ratingController;

  late final TextEditingController
      _imageController;

  late final TextEditingController
      _servicesController;

  bool _saving = false;

  bool get isEditing =>
      widget.provider != null;

  // =========================================================
  // INIT
  // =========================================================

  @override
  void initState() {
    super.initState();

    final data =
        widget.provider?.data() ?? {};

    _nameController =
        TextEditingController(
      text: (data['name'] ?? '')
          .toString(),
    );

    _categoryController =
        TextEditingController(
      text: (data['category'] ??
              data['specialty'] ??
              '')
          .toString(),
    );

    _descriptionController =
        TextEditingController(
      text: (data['description'] ?? '')
          .toString(),
    );

    _priceController =
        TextEditingController(
      text: (data['price'] ??
              data['hourlyRate'] ??
              '')
          .toString(),
    );

    _ratingController =
        TextEditingController(
      text: (data['rating'] ?? '')
          .toString(),
    );

    _imageController =
        TextEditingController(
      text: (data['imageUrl'] ?? '')
          .toString(),
    );

    final services =
        data['servicesOffered'];

    if (services is List) {
      _servicesController =
          TextEditingController(
        text: services.join(', '),
      );
    } else {
      _servicesController =
          TextEditingController();
    }
  }

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _categoryController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _ratingController.dispose();
    _imageController.dispose();
    _servicesController.dispose();

    super.dispose();
  }

  // =========================================================
  // SAVE PROVIDER
  // =========================================================

  Future<void> _saveProvider() async {
    if (!_formKey.currentState!
        .validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final services =
          _servicesController.text
              .split(',')
              .map(
                (service) =>
                    service.trim(),
              )
              .where(
                (service) =>
                    service.isNotEmpty,
              )
              .toList();

      final data = {
        'name':
            _nameController.text.trim(),

        'category':
            _categoryController.text.trim(),

        'description':
            _descriptionController
                .text
                .trim(),

        'price':
            double.tryParse(
                  _priceController.text,
                ) ??
                0,

        'rating':
            double.tryParse(
                  _ratingController.text,
                ) ??
                0,

        'imageUrl':
            _imageController.text.trim(),

        'servicesOffered':
            services,
      };

      final collection =
          FirebaseFirestore.instance
              .collection(
        _collection,
      );

      if (isEditing) {
        await collection
            .doc(widget.provider!.id)
            .update(data);
      } else {
        await collection.add(data);
      }

      if (!mounted) return;

      Navigator.pop(context);

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Provider updated successfully.'
                : 'Provider added successfully.',
          ),
          backgroundColor:
              primaryGreen,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Failed to save provider: $e',
          ),
          backgroundColor:
              Colors.red,
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // BUILD FORM
  // =========================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    final bottom =
        MediaQuery.of(context)
            .viewInsets
            .bottom;

    return Container(
      padding: EdgeInsets.only(
        bottom: bottom,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            20,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                // =================================================
                // HANDLE
                // =================================================

                Center(
                  child: Container(
                    width: 45,
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.grey.shade300,
                      borderRadius:
                          BorderRadius.circular(
                        10,
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                  height: 20,
                ),

                // =================================================
                // TITLE
                // =================================================

                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration:
                          BoxDecoration(
                        color: lightGreen,
                        borderRadius:
                            BorderRadius.circular(
                          13,
                        ),
                      ),
                      child:
                          const Icon(
                        Icons
                            .business_outlined,
                        color:
                            primaryGreen,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            isEditing
                                ? 'Edit Provider'
                                : 'Add Provider',
                            style:
                                const TextStyle(
                              color:
                                  darkText,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight
                                      .bold,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          const Text(
                            'Enter provider information below.',
                            style:
                                TextStyle(
                              color:
                                  secondaryText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 22,
                ),

                // =================================================
                // PROVIDER NAME
                // =================================================

                _buildField(
                  controller:
                      _nameController,
                  label:
                      'Provider Name',
                  icon: Icons
                      .business_outlined,
                  requiredField: true,
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // CATEGORY
                // =================================================

                _buildField(
                  controller:
                      _categoryController,
                  label:
                      'Category',
                  icon: Icons
                      .category_outlined,
                  requiredField: true,
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // DESCRIPTION
                // =================================================

                _buildField(
                  controller:
                      _descriptionController,
                  label:
                      'Description',
                  icon: Icons
                      .description_outlined,
                  maxLines: 3,
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // SERVICES
                // =================================================

                _buildField(
                  controller:
                      _servicesController,
                  label:
                      'Services Offered',
                  hint:
                      'Repair, Installation, Cleaning',
                  icon: Icons
                      .build_outlined,
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // PRICE + RATING
                // =================================================

                Row(
                  children: [
                    Expanded(
                      child:
                          _buildField(
                        controller:
                            _priceController,
                        label:
                            'Price',
                        icon: Icons
                            .payments_outlined,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                        requiredField:
                            true,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          _buildField(
                        controller:
                            _ratingController,
                        label:
                            'Rating',
                        hint:
                            '0 - 5',
                        icon: Icons
                            .star_outline,
                        keyboardType:
                            const TextInputType
                                .numberWithOptions(
                          decimal: true,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(
                  height: 14,
                ),

                // =================================================
                // IMAGE URL
                // =================================================

                _buildField(
                  controller:
                      _imageController,
                  label:
                      'Image URL',
                  hint:
                      'https://example.com/image.jpg',
                  icon: Icons
                      .image_outlined,
                ),

                const SizedBox(
                  height: 24,
                ),

                // =================================================
                // SAVE BUTTON
                // =================================================

                SizedBox(
                  width:
                      double.infinity,
                  height: 52,
                  child:
                      ElevatedButton(
                    onPressed:
                        _saving
                            ? null
                            : _saveProvider,
                    style:
                        ElevatedButton
                            .styleFrom(
                      backgroundColor:
                          primaryGreen,
                      foregroundColor:
                          Colors.white,
                      disabledBackgroundColor:
                          Colors.grey
                              .shade300,
                      elevation: 0,
                      shape:
                          RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius
                                .circular(
                          14,
                        ),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child:
                                CircularProgressIndicator(
                              strokeWidth:
                                  2,
                              color:
                                  Colors.white,
                            ),
                          )
                        : Text(
                            isEditing
                                ? 'Update Provider'
                                : 'Add Provider',
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .bold,
                              fontSize: 15,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // FORM FIELD
  // =========================================================

  Widget _buildField({
    required TextEditingController
        controller,
    required String label,
    required IconData icon,
    String? hint,
    bool requiredField = false,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: darkText,
        fontSize: 14,
      ),
      decoration:
          InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(
          icon,
          color: primaryGreen,
        ),
        filled: true,
        fillColor:
            backgroundColor,
        labelStyle:
            const TextStyle(
          color: secondaryText,
        ),
        hintStyle:
            const TextStyle(
          color:
              Color(0xFFA0AAA4),
          fontSize: 12,
        ),
        border:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide.none,
        ),
        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.black.withValues(
              alpha: 0.05,
            ),
          ),
        ),
        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              const BorderSide(
            color: primaryGreen,
            width: 1.5,
          ),
        ),
        errorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.red.shade300,
          ),
        ),
        focusedErrorBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(
            14,
          ),
          borderSide:
              BorderSide(
            color:
                Colors.red.shade400,
            width: 1.5,
          ),
        ),
      ),
      validator: requiredField
          ? (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return '$label is required';
              }

              return null;
            }
          : null,
    );
  }
}