import 'package:flutter/material.dart';

import '../review_service.dart';

class WriteReviewScreen extends StatefulWidget {
  final String bookingId;
  final String providerId;
  final String providerName;

  const WriteReviewScreen({
    super.key,
    required this.bookingId,
    required this.providerId,
    required this.providerName,
  });

  @override
  State<WriteReviewScreen> createState() =>
      _WriteReviewScreenState();
}

class _WriteReviewScreenState
    extends State<WriteReviewScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color darkGreen = Color(0xFF388E3C);
  static const Color darkText = Color(0xFF1F2937);
  static const Color secondaryText = Color(0xFF6B7280);
  static const Color lightBackground = Color(0xFFF7FAF8);

  // =========================================================
  // CONTROLLERS
  // =========================================================

  final TextEditingController _commentController =
      TextEditingController();

  // =========================================================
  // STATE
  // =========================================================

  double _rating = 5.0;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    _commentController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  // =========================================================
  // SUBMIT REVIEW
  // =========================================================

  Future<void> _submitReview() async {
    final comment =
        _commentController.text.trim();

    if (comment.isEmpty) {
      _showMessage(
        'Please write a review.',
        isError: true,
      );
      return;
    }

    if (_rating < 1) {
      _showMessage(
        'Please select a rating.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await ReviewService().addReview(
        bookingId: widget.bookingId,
        providerId: widget.providerId,
        providerName: widget.providerName,
        rating: _rating,
        comment: comment,
      );

      if (!mounted) return;

      _showMessage(
        'Review submitted successfully!',
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        e.toString().replaceFirst(
          'Exception: ',
          '',
        ),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // =========================================================
  // STAR RATING
  // =========================================================

  Widget _buildStar(int starNumber) {
    final bool isSelected =
        starNumber <= _rating;

    return IconButton(
      tooltip: '$starNumber star',
      onPressed: _isSubmitting
          ? null
          : () {
              setState(() {
                _rating =
                    starNumber.toDouble();
              });
            },
      icon: Icon(
        isSelected
            ? Icons.star_rounded
            : Icons.star_outline_rounded,
      ),
      iconSize: 42,
      color: Colors.amber.shade600,
    );
  }

  // =========================================================
  // MESSAGE
  // =========================================================

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    ScaffoldMessenger.of(context)
        .hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor:
            isError
                ? Colors.red.shade600
                : primaryGreen,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(12),
        ),
        margin:
            const EdgeInsets.all(16),
      ),
    );
  }

  // =========================================================
  // PROVIDER HEADER
  // =========================================================

  Widget _buildProviderHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: primaryGreen
              .withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 42,
            backgroundColor:
                primaryGreen.withValues(
              alpha: 0.10,
            ),
            child: const Icon(
              Icons.business_center_outlined,
              size: 45,
              color: primaryGreen,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            widget.providerName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'How was your experience?',
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // RATING SECTION
  // =========================================================

  Widget _buildRatingSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Rate your experience',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkText,
            ),
          ),

          const SizedBox(height: 8),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              _buildStar(1),
              _buildStar(2),
              _buildStar(3),
              _buildStar(4),
              _buildStar(5),
            ],
          ),

          const SizedBox(height: 2),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: Text(
              '${_rating.toInt()} / 5',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // REVIEW FIELD
  // =========================================================

  Widget _buildReviewField() {
    final int characterCount =
        _commentController.text.length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),

          const SizedBox(height: 6),

          const Text(
            'Share your experience with this provider.',
            style: TextStyle(
              fontSize: 13,
              color: secondaryText,
            ),
          ),

          const SizedBox(height: 12),

          TextField(
            controller:
                _commentController,
            enabled: !_isSubmitting,
            maxLines: 6,
            maxLength: 500,
            textInputAction:
                TextInputAction.newline,
            decoration: InputDecoration(
              hintText:
                  'Tell us about your experience...',
              hintStyle: TextStyle(
                color: Colors.grey.shade500,
              ),
              filled: true,
              fillColor:
                  lightBackground,
              border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide:
                    BorderSide.none,
              ),
              enabledBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey
                      .shade200,
                ),
              ),
              focusedBorder:
                  OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(14),
                borderSide:
                    const BorderSide(
                  color: primaryGreen,
                  width: 2,
                ),
              ),
              contentPadding:
                  const EdgeInsets.all(14),
              counterText: '',
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment:
                Alignment.centerRight,
            child: Text(
              '$characterCount / 500',
              style: TextStyle(
                fontSize: 12,
                color: characterCount >= 450
                    ? Colors.orange.shade700
                    : secondaryText,
                fontWeight:
                    characterCount >= 450
                        ? FontWeight.w600
                        : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // SUBMIT BUTTON
  // =========================================================

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed:
            _isSubmitting
                ? null
                : _submitReview,
        icon: _isSubmitting
            ? const SizedBox(
                width: 21,
                height: 21,
                child:
                    CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(
                Icons.star_rounded,
              ),
        label: Text(
          _isSubmitting
              ? 'Submitting...'
              : 'Submit Review',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style:
            ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              primaryGreen.withValues(
            alpha: 0.55,
          ),
          disabledForegroundColor:
              Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // =========================================================
  // INFO BOX
  // =========================================================

  Widget _buildInfoBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: primaryGreen.withValues(
          alpha: 0.07,
        ),
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: primaryGreen.withValues(
            alpha: 0.12,
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 19,
            color: darkGreen,
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(
              'You can review this provider only once for this booking.',
              style: TextStyle(
                fontSize: 12.5,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,

      appBar: AppBar(
        title: const Text(
          'Write a Review',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: darkText,
        elevation: 0,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              _buildProviderHeader(),

              const SizedBox(height: 16),

              _buildRatingSection(),

              const SizedBox(height: 16),

              _buildReviewField(),

              const SizedBox(height: 20),

              _buildSubmitButton(),

              const SizedBox(height: 14),

              _buildInfoBox(),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

