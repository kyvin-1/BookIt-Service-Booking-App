import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/firestore_provider.dart';
import '../../providers/provider_details_screen.dart';
import '../../widgets/provider_card.dart';
import '../notifications/notifications_screen.dart';

class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() =>
      _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  final TextEditingController _searchController =
      TextEditingController();

  final ScrollController _scrollController =
      ScrollController();

  String _searchText = '';
  String _selectedCategory = 'All';

  static const Color _green = Color(0xFF1D9B61);
  static const Color _background = Color(0xFFF5F9F7);
  static const Color _textDark = Color(0xFF17231D);

  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {
        _searchText =
            _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // =========================================================
  // SCROLL TO PROVIDERS
  // =========================================================

  void _scrollToProviders() {
    _scrollController.animateTo(
      520,
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
    );
  }

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
  // OPEN NOTIFICATIONS
  // =========================================================

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const NotificationsScreen(),
      ),
    );
  }

  // =========================================================
  // FILTER PROVIDERS
  // =========================================================

  List<dynamic> _filterProviders(
    List<dynamic> providers,
  ) {
    return providers.where((provider) {
      final name =
          provider.name.toString().toLowerCase();

      final specialty =
          provider.specialty.toString().toLowerCase();

      final matchesSearch =
          _searchText.isEmpty ||
          name.contains(_searchText) ||
          specialty.contains(_searchText);

      final matchesCategory =
          _selectedCategory == 'All' ||
          specialty ==
              _selectedCategory.toLowerCase();

      return matchesSearch && matchesCategory;
    }).toList();
  }

  // =========================================================
  // CATEGORY LIST
  // =========================================================

  List<String> _getCategories(
    List<dynamic> providers,
  ) {
    final categories = <String>{};

    for (final provider in providers) {
      final specialty =
          provider.specialty.toString().trim();

      if (specialty.isNotEmpty) {
        categories.add(specialty);
      }
    }

    return [
      'All',
      ...categories,
    ];
  }

  // =========================================================
  // CATEGORY ICON
  // =========================================================

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.plumbing_outlined;

      case 'cleaning':
        return Icons.cleaning_services_outlined;

      case 'electrical':
        return Icons.electrical_services_outlined;

      case 'car repair':
      case 'automotive':
        return Icons.car_repair_outlined;

      case 'beauty':
        return Icons.spa_outlined;

      case 'gardening':
        return Icons.yard_outlined;

      case 'painting':
        return Icons.format_paint_outlined;

      case 'moving':
        return Icons.local_shipping_outlined;

      default:
        return Icons.home_repair_service_outlined;
    }
  }

  // =========================================================
  // NOTIFICATION BUTTON
  // =========================================================

  Widget _buildNotificationButton() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return IconButton(
        tooltip: 'Notifications',
        onPressed: _openNotifications,
        icon: const Icon(
          Icons.notifications_none_rounded,
          color: _textDark,
          size: 25,
        ),
      );
    }

    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _notificationStream(user.uid),
      builder: (
        context,
        snapshot,
      ) {
        int unreadCount = 0;

        if (snapshot.hasData) {
          for (final document
              in snapshot.data!.docs) {
            final data = document.data();

            if (data['isRead'] != true) {
              unreadCount++;
            }
          }
        }

        return IconButton(
          tooltip: 'Notifications',
          onPressed: _openNotifications,
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(
                Icons.notifications_none_rounded,
                color: _textDark,
                size: 25,
              ),

              if (unreadCount > 0)
                Positioned(
                  right: -4,
                  top: -5,
                  child: Container(
                    constraints:
                        const BoxConstraints(
                      minWidth: 17,
                      minHeight: 17,
                    ),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 1,
                    ),
                    decoration:
                        BoxDecoration(
                      color: Colors.red,
                      borderRadius:
                          BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      unreadCount > 99
                          ? '99+'
                          : unreadCount.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    final providersAsync =
        ref.watch(firestoreProvidersProvider);

    return Scaffold(
      backgroundColor: _background,

      // =====================================================
      // APP BAR
      // =====================================================

      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: AppConstants.padding,

        title: Row(
          children: [
            ClipRRect(
              borderRadius:
                  BorderRadius.circular(12),
              child: Image.asset(
                'assets/icon/bookit_app_icon.png',
                width: 38,
                height: 38,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(width: 10),

            const Text(
              'BookIt',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: _textDark,
              ),
            ),
          ],
        ),

        actions: [
          _buildNotificationButton(),

          Padding(
            padding:
                const EdgeInsets.only(right: 14),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color:
                    _green.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                color: _green,
                size: 21,
              ),
            ),
          ),
        ],
      ),

      // =====================================================
      // BODY
      // =====================================================

      body: providersAsync.when(

        // ===================================================
        // LOADING
        // ===================================================

        loading: () => const Center(
          child: CircularProgressIndicator(
            color: _green,
          ),
        ),

        // ===================================================
        // ERROR
        // ===================================================

        error: (error, stack) =>
            _buildErrorState(
          context,
          error,
        ),

        // ===================================================
        // DATA
        // ===================================================

        data: (providers) {
          final filteredProviders =
              _filterProviders(providers);

          final categories =
              _getCategories(providers);

          return RefreshIndicator(
            color: _green,

            onRefresh: () async {
              ref.invalidate(
                firestoreProvidersProvider,
              );

              await ref.read(
                firestoreProvidersProvider.future,
              );
            },

            child: CustomScrollView(
              controller: _scrollController,

              physics:
                  const AlwaysScrollableScrollPhysics(),

              slivers: [

                // =================================================
                // GREETING
                // =================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      AppConstants.padding,
                      18,
                      AppConstants.padding,
                      0,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,

                      children: [
                        Row(
                          children: [
                            Text(
                              'Good day',
                              style: TextStyle(
                                fontSize: 15,
                                color:
                                    Colors.grey[600],
                                fontWeight:
                                    FontWeight.w500,
                              ),
                            ),

                            const SizedBox(width: 4),

                            const Text(
                              '👋',
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          'Find a service you need',
                          style: TextStyle(
                            fontSize: 27,
                            height: 1.12,
                            fontWeight:
                                FontWeight.w800,
                            color: _textDark,
                          ),
                        ),

                        const SizedBox(height: 7),

                        Text(
                          'Book trusted professionals near you.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================
                // SEARCH
                // =================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      AppConstants.padding,
                      18,
                      AppConstants.padding,
                      16,
                    ),

                    child: Container(
                      height: 52,

                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(17),

                        border: Border.all(
                          color:
                              Colors.grey.shade200,
                        ),

                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withValues(
                              alpha: 0.035,
                            ),
                            blurRadius: 12,
                            offset:
                                const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: TextField(
                        controller:
                            _searchController,

                        textInputAction:
                            TextInputAction.search,

                        decoration:
                            InputDecoration(
                          hintText:
                              'Search services or providers',

                          hintStyle: TextStyle(
                            color:
                                Colors.grey[500],
                            fontSize: 14,
                          ),

                          prefixIcon:
                              const Icon(
                            Icons.search_rounded,
                            color: _textDark,
                            size: 23,
                          ),

                          suffixIcon:
                              _searchText.isNotEmpty
                                  ? IconButton(
                                      tooltip:
                                          'Clear search',
                                      icon:
                                          const Icon(
                                        Icons
                                            .close_rounded,
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        _searchController
                                            .clear();
                                      },
                                    )
                                  : null,

                          border:
                              InputBorder.none,

                          contentPadding:
                              const EdgeInsets
                                  .symmetric(
                            vertical: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // =================================================
                // PROMO BANNER
                // =================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal:
                          AppConstants.padding,
                    ),

                    child: Container(
                      height: 150,

                      decoration:
                          BoxDecoration(
                        gradient:
                            const LinearGradient(
                          colors: [
                            Color(0xFF147A4A),
                            Color(0xFF35AD70),
                          ],
                          begin:
                              Alignment.centerLeft,
                          end:
                              Alignment.centerRight,
                        ),

                        borderRadius:
                            BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(
                              0xFF1D9B61,
                            ).withValues(
                              alpha: 0.20,
                            ),
                            blurRadius: 18,
                            offset:
                                const Offset(0, 8),
                          ),
                        ],
                      ),

                      child: Stack(
                        children: [

                          // Decorative circles
                          Positioned(
                            right: -45,
                            top: -55,

                            child: Container(
                              width: 170,
                              height: 170,

                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.08,
                                ),
                              ),
                            ),
                          ),

                          Positioned(
                            right: 35,
                            bottom: -50,

                            child: Container(
                              width: 90,
                              height: 90,

                              decoration:
                                  BoxDecoration(
                                shape:
                                    BoxShape.circle,
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.05,
                                ),
                              ),
                            ),
                          ),

                          Padding(
                            padding:
                                const EdgeInsets
                                    .fromLTRB(
                              20,
                              17,
                              20,
                              15,
                            ),

                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,

                              children: [
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),

                                  decoration:
                                      BoxDecoration(
                                    color: Colors
                                        .white
                                        .withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      20,
                                    ),
                                  ),

                                  child: const Text(
                                    'BOOKIT',
                                    style:
                                        TextStyle(
                                      color:
                                          Colors.white,
                                      fontSize: 10,
                                      fontWeight:
                                          FontWeight
                                              .w800,
                                      letterSpacing:
                                          0.8,
                                    ),
                                  ),
                                ),

                                const SizedBox(
                                  height: 8,
                                ),

                                const Text(
                                  'Your service,\njust a booking away.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white,
                                    fontSize: 19,
                                    height: 1.12,
                                    fontWeight:
                                        FontWeight
                                            .w800,
                                  ),
                                ),

                                const SizedBox(
                                  height: 7,
                                ),

                                const Text(
                                  'Find trusted professionals today.',
                                  style:
                                      TextStyle(
                                    color:
                                        Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // =================================================
                          // BOOK NOW BUTTON
                          // =================================================

                          Positioned(
                            right: 18,
                            bottom: 18,

                            child: Material(
                              color:
                                  Colors.white,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                20,
                              ),

                              child: InkWell(
                                borderRadius:
                                    BorderRadius
                                        .circular(
                                  20,
                                ),

                                onTap:
                                    _scrollToProviders,

                                child:
                                    const Padding(
                                  padding:
                                      EdgeInsets
                                          .symmetric(
                                    horizontal: 14,
                                    vertical: 9,
                                  ),

                                  child: Row(
                                    mainAxisSize:
                                        MainAxisSize
                                            .min,

                                    children: [
                                      Text(
                                        'Book Now',
                                        style:
                                            TextStyle(
                                          color:
                                              Color(
                                            0xFF147A4A,
                                          ),
                                          fontSize:
                                              12,
                                          fontWeight:
                                              FontWeight
                                                  .w800,
                                        ),
                                      ),

                                      SizedBox(
                                        width: 5,
                                      ),

                                      Icon(
                                        Icons
                                            .arrow_forward_rounded,
                                        color:
                                            Color(
                                          0xFF147A4A,
                                        ),
                                        size: 17,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // =================================================
                // POPULAR SERVICES
                // =================================================

                if (categories.length > 1)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding:
                          const EdgeInsets.fromLTRB(
                        AppConstants.padding,
                        24,
                        AppConstants.padding,
                        0,
                      ),

                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,

                        children: [
                          Row(
                            children: [
                              const Text(
                                'Popular Services',
                                style:
                                    TextStyle(
                                  fontSize: 19,
                                  fontWeight:
                                      FontWeight.w800,
                                  color: _textDark,
                                ),
                              ),

                              const Spacer(),

                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory =
                                        'All';
                                  });
                                },

                                child:
                                    const Row(
                                  children: [
                                    Text(
                                      'See All',
                                      style:
                                          TextStyle(
                                        color:
                                            _green,
                                        fontSize:
                                            13,
                                        fontWeight:
                                            FontWeight
                                                .w700,
                                      ),
                                    ),

                                    SizedBox(
                                      width: 3,
                                    ),

                                    Icon(
                                      Icons
                                          .arrow_forward_ios_rounded,
                                      color:
                                          _green,
                                      size: 12,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 12,
                          ),

                          SizedBox(
                            height: 118,

                            child:
                                ListView.separated(
                              scrollDirection:
                                  Axis.horizontal,

                              physics:
                                  const BouncingScrollPhysics(),

                              itemCount:
                                  categories.length -
                                      1,

                              separatorBuilder:
                                  (
                                context,
                                index,
                              ) {
                                return const SizedBox(
                                  width: 12,
                                );
                              },

                              itemBuilder:
                                  (
                                context,
                                index,
                              ) {
                                final category =
                                    categories[
                                        index + 1];

                                final isSelected =
                                    _selectedCategory ==
                                        category;

                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedCategory =
                                          category;
                                    });
                                  },

                                  child:
                                      AnimatedContainer(
                                    duration:
                                        const Duration(
                                      milliseconds:
                                          220,
                                    ),

                                    curve:
                                        Curves.easeOut,

                                    width: 112,

                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 12,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color:
                                          isSelected
                                              ? _green
                                              : Colors
                                                  .white,

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),

                                      border:
                                          Border.all(
                                        color:
                                            isSelected
                                                ? _green
                                                : Colors
                                                    .grey
                                                    .shade200,
                                        width:
                                            isSelected
                                                ? 1.5
                                                : 1,
                                      ),

                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors
                                              .black
                                              .withValues(
                                            alpha:
                                                isSelected
                                                    ? 0.08
                                                    : 0.035,
                                          ),
                                          blurRadius:
                                              isSelected
                                                  ? 12
                                                  : 8,
                                          offset:
                                              const Offset(
                                            0,
                                            4,
                                          ),
                                        ),
                                      ],
                                    ),

                                    child:
                                        Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,

                                      children: [
                                        AnimatedContainer(
                                          duration:
                                              const Duration(
                                            milliseconds:
                                                220,
                                          ),

                                          width: 46,
                                          height: 46,

                                          decoration:
                                              BoxDecoration(
                                            color:
                                                isSelected
                                                    ? Colors
                                                        .white
                                                        .withValues(
                                                        alpha:
                                                            0.18,
                                                      )
                                                    : _green
                                                        .withValues(
                                                        alpha:
                                                            0.10,
                                                      ),

                                            borderRadius:
                                                BorderRadius
                                                    .circular(
                                              14,
                                            ),
                                          ),

                                          child:
                                              Icon(
                                            _categoryIcon(
                                              category,
                                            ),

                                            color:
                                                isSelected
                                                    ? Colors
                                                        .white
                                                    : _green,

                                            size: 24,
                                          ),
                                        ),

                                        const SizedBox(
                                          height: 9,
                                        ),

                                        Text(
                                          category,
                                          maxLines:
                                              1,
                                          overflow:
                                              TextOverflow
                                                  .ellipsis,
                                          textAlign:
                                              TextAlign
                                                  .center,

                                          style:
                                              TextStyle(
                                            fontSize:
                                                12,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                            color:
                                                isSelected
                                                    ? Colors
                                                        .white
                                                    : _textDark,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // =================================================
                // PROVIDERS HEADER
                // =================================================

                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      AppConstants.padding,
                      25,
                      AppConstants.padding,
                      11,
                    ),

                    child: Row(
                      children: [
                        const Text(
                          'Available Providers',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight:
                                FontWeight.w800,
                            color: _textDark,
                          ),
                        ),

                        const Spacer(),

                        Container(
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 9,
                            vertical: 5,
                          ),

                          decoration:
                              BoxDecoration(
                            color:
                                _green.withValues(
                              alpha: 0.08,
                            ),

                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),

                          child: Text(
                            '${filteredProviders.length} found',

                            style:
                                const TextStyle(
                              fontSize: 12,
                              color: _green,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // =================================================
                // NO PROVIDERS
                // =================================================

                if (providers.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,

                    child: _buildEmptyState(
                      icon:
                          Icons.storefront_outlined,
                      title:
                          'No service providers yet',
                      message:
                          'Service providers will appear here once they are added.',
                    ),
                  )

                // =================================================
                // NO SEARCH RESULTS
                // =================================================

                else if (filteredProviders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,

                    child: _buildEmptyState(
                      icon:
                          Icons.search_off_rounded,
                      title:
                          'No matching providers',
                      message:
                          'Try a different search or category.',
                    ),
                  )

                // =================================================
                // PROVIDER LIST
                // =================================================

                else
                  SliverPadding(
                    padding:
                        const EdgeInsets.fromLTRB(
                      AppConstants.padding,
                      0,
                      AppConstants.padding,
                      30,
                    ),

                    sliver:
                        SliverList.builder(
                      itemCount:
                          filteredProviders.length,

                      itemBuilder:
                          (context, index) {
                        final provider =
                            filteredProviders[
                                index];

                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 14,
                          ),

                          child: ProviderCard(
                            provider: provider,

                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) =>
                                          ProviderDetailsScreen(
                                    provider:
                                        provider,
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  // =========================================================
  // ERROR STATE
  // =========================================================

  Widget _buildErrorState(
    BuildContext context,
    Object error,
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
              padding:
                  const EdgeInsets.all(18),

              decoration:
                  BoxDecoration(
                color:
                    _green.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_outlined,
                size: 44,
                color: _green,
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Unable to load providers',
              style: TextStyle(
                fontSize: 19,
                fontWeight:
                    FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Please check your internet connection and try again.',
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                ref.invalidate(
                  firestoreProvidersProvider,
                );
              },

              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    _green,
              ),

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label:
                  const Text(
                'Try Again',
              ),
            ),

            const SizedBox(height: 10),

            Text(
              error.toString(),
              maxLines: 2,
              overflow:
                  TextOverflow.ellipsis,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color:
                    Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================
  // EMPTY STATE
  // =========================================================

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              padding:
                  const EdgeInsets.all(20),

              decoration:
                  BoxDecoration(
                color:
                    _green.withValues(
                  alpha: 0.08,
                ),
                shape:
                    BoxShape.circle,
              ),

              child: Icon(
                icon,
                size: 48,
                color: _green,
              ),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 18,
                fontWeight:
                    FontWeight.bold,
                color: _textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign:
                  TextAlign.center,
              style: TextStyle(
                color:
                    Colors.grey[600],
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}