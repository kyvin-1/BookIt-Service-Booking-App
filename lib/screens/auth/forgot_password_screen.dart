import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  // =========================================================
  // COLORS
  // =========================================================

  static const Color primaryGreen = Color(0xFF1D9B61);
  static const Color darkText = Color(0xFF17231D);
  static const Color secondaryText = Color(0xFF69736D);

  // =========================================================
  // FORM
  // =========================================================

  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _emailSent = false;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // =========================================================
  // SEND RESET EMAIL
  // =========================================================

  Future<void> _sendResetEmail() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.resetPassword(
        email: _emailController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password reset email sent successfully.',
          ),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final message = e
          .toString()
          .replaceFirst('Exception: ', '');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,

      body: Stack(
        children: [
          // =====================================================
          // BACKGROUND
          // =====================================================

          Positioned.fill(
            child: Image.asset(
              'assets/auth/booked_background.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // =====================================================
          // OVERLAY
          // =====================================================

          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.05),
                    Colors.black.withValues(alpha: 0.12),
                    Colors.black.withValues(alpha: 0.25),
                  ],
                ),
              ),
            ),
          ),

          // =====================================================
          // CONTENT
          // =====================================================

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop =
                    constraints.maxWidth >= 700;

                return SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),

                  padding: EdgeInsets.symmetric(
                    horizontal:
                        isDesktop ? 40 : 18,
                    vertical: 18,
                  ),

                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          constraints.maxHeight - 36,
                    ),

                    child: Column(
                      children: [
                        // =======================================
                        // BOOKIT BRAND
                        // =======================================

                        Align(
                          alignment: Alignment.topLeft,

                          child: Row(
                            mainAxisSize:
                                MainAxisSize.min,

                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                padding:
                                    const EdgeInsets.all(
                                  3,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius
                                          .circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 10,
                                      offset:
                                          const Offset(
                                        0,
                                        4,
                                      ),
                                    ),
                                  ],
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius
                                          .circular(9),

                                  child: Image.asset(
                                    'assets/icon/bookit_app_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              const Text(
                                'BookIt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color:
                                          Colors.black54,
                                      blurRadius: 6,
                                      offset:
                                          Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // =======================================
                        // SPACE
                        // =======================================

                        SizedBox(
                          height:
                              isDesktop ? 155 : 100,
                        ),

                        // =======================================
                        // CARD
                        // =======================================

                        ConstrainedBox(
                          constraints:
                              const BoxConstraints(
                            maxWidth: 430,
                          ),

                          child: Container(
                            width: double.infinity,

                            padding:
                                const EdgeInsets.fromLTRB(
                              24,
                              26,
                              24,
                              22,
                            ),

                            decoration:
                                BoxDecoration(
                              color: Colors.white
                                  .withValues(
                                alpha: 0.96,
                              ),

                              borderRadius:
                                  BorderRadius.circular(
                                24,
                              ),

                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withValues(
                                    alpha: 0.20,
                                  ),
                                  blurRadius: 28,
                                  offset:
                                      const Offset(
                                    0,
                                    12,
                                  ),
                                ),
                              ],
                            ),

                            child: Form(
                              key: _formKey,

                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .stretch,

                                children: [
                                  // =========================
                                  // ICON
                                  // =========================

                                  Center(
                                    child: Container(
                                      width: 62,
                                      height: 62,

                                      decoration:
                                          BoxDecoration(
                                        color:
                                            const Color(
                                          0xFFE9F7EF,
                                        ),
                                        shape:
                                            BoxShape.circle,
                                      ),

                                      child: const Icon(
                                        Icons
                                            .lock_reset_rounded,
                                        color:
                                            primaryGreen,
                                        size: 31,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // =========================
                                  // TITLE
                                  // =========================

                                  const Text(
                                    'Forgot password?',
                                    textAlign:
                                        TextAlign.center,

                                    style: TextStyle(
                                      fontSize: 25,
                                      fontWeight:
                                          FontWeight.w800,
                                      color: darkText,
                                      letterSpacing:
                                          -0.4,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 7,
                                  ),

                                  Text(
                                    _emailSent
                                        ? 'Check your inbox for the password reset link.'
                                        : 'Enter your email and we’ll send you a link to reset your password.',
                                    textAlign:
                                        TextAlign.center,

                                    style:
                                        const TextStyle(
                                      fontSize: 13.5,
                                      color:
                                          secondaryText,
                                      height: 1.4,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 24,
                                  ),

                                  // =========================
                                  // EMAIL LABEL
                                  // =========================

                                  const Text(
                                    'Email address',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight:
                                          FontWeight.w600,
                                      color: darkText,
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 6,
                                  ),

                                  // =========================
                                  // EMAIL FIELD
                                  // =========================

                                  TextFormField(
                                    controller:
                                        _emailController,

                                    keyboardType:
                                        TextInputType
                                            .emailAddress,

                                    textInputAction:
                                        TextInputAction
                                            .done,

                                    autocorrect: false,

                                    decoration:
                                        InputDecoration(
                                      hintText:
                                          'you@example.com',

                                      prefixIcon:
                                          const Icon(
                                        Icons
                                            .email_outlined,
                                        color:
                                            secondaryText,
                                      ),

                                      filled: true,

                                      fillColor:
                                          const Color(
                                        0xFFF7FAF8,
                                      ),

                                      contentPadding:
                                          const EdgeInsets
                                              .symmetric(
                                        horizontal: 15,
                                        vertical: 15,
                                      ),

                                      hintStyle:
                                          const TextStyle(
                                        color:
                                            Color(
                                          0xFF9AA49F,
                                        ),
                                        fontSize: 14,
                                      ),

                                      border:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          13,
                                        ),
                                        borderSide:
                                            BorderSide.none,
                                      ),

                                      enabledBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          13,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              Color(
                                            0xFFE1E8E4,
                                          ),
                                        ),
                                      ),

                                      focusedBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          13,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              primaryGreen,
                                          width: 1.5,
                                        ),
                                      ),

                                      errorBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          13,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              Colors.red,
                                        ),
                                      ),

                                      focusedErrorBorder:
                                          OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius
                                                .circular(
                                          13,
                                        ),
                                        borderSide:
                                            const BorderSide(
                                          color:
                                              Colors.red,
                                          width: 1.3,
                                        ),
                                      ),
                                    ),

                                    validator: (value) {
                                      final email =
                                          value?.trim() ??
                                              '';

                                      if (email.isEmpty) {
                                        return 'Please enter your email';
                                      }

                                      if (!email
                                              .contains(
                                            '@',
                                          ) ||
                                          !email
                                              .contains(
                                            '.',
                                          )) {
                                        return 'Please enter a valid email';
                                      }

                                      return null;
                                    },

                                    onFieldSubmitted:
                                        (_) {
                                      if (!_isLoading) {
                                        _sendResetEmail();
                                      }
                                    },
                                  ),

                                  const SizedBox(
                                    height: 18,
                                  ),

                                  // =========================
                                  // SEND BUTTON
                                  // =========================

                                  SizedBox(
                                    height: 51,

                                    child:
                                        ElevatedButton(
                                      onPressed:
                                          _isLoading
                                              ? null
                                              : _sendResetEmail,

                                      style:
                                          ElevatedButton
                                              .styleFrom(
                                        backgroundColor:
                                            primaryGreen,

                                        foregroundColor:
                                            Colors.white,

                                        disabledBackgroundColor:
                                            primaryGreen
                                                .withValues(
                                          alpha: 0.55,
                                        ),

                                        elevation: 0,

                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(
                                            13,
                                          ),
                                        ),
                                      ),

                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(
                                                strokeWidth:
                                                    2.5,
                                                color:
                                                    Colors.white,
                                              ),
                                            )
                                          : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                              children: [
                                                Text(
                                                  _emailSent
                                                      ? 'Send Again'
                                                      : 'Send Reset Link',
                                                  style:
                                                      const TextStyle(
                                                    fontSize:
                                                        15.5,
                                                    fontWeight:
                                                        FontWeight
                                                            .w700,
                                                  ),
                                                ),

                                                const SizedBox(
                                                  width: 8,
                                                ),

                                                const Icon(
                                                  Icons
                                                      .arrow_forward_rounded,
                                                  size: 19,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),

                                  const SizedBox(
                                    height: 16,
                                  ),

                                  // =========================
                                  // BACK TO LOGIN
                                  // =========================

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children: [
                                      const Text(
                                        'Remember your password?',
                                        style:
                                            TextStyle(
                                          fontSize: 13,
                                          color:
                                              secondaryText,
                                        ),
                                      ),

                                      TextButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : () {
                                                    Navigator
                                                        .pop(
                                                      context,
                                                    );
                                                  },

                                        style:
                                            TextButton.styleFrom(
                                          padding:
                                              const EdgeInsets
                                                  .only(
                                            left: 5,
                                          ),
                                        ),

                                        child:
                                            const Text(
                                          'Sign in',
                                          style:
                                              TextStyle(
                                            color:
                                                primaryGreen,
                                            fontWeight:
                                                FontWeight
                                                    .w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  // =========================
                                  // SECURITY
                                  // =========================

                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children: [
                                      Icon(
                                        Icons
                                            .verified_user_outlined,
                                        size: 14,
                                        color: Colors
                                            .grey
                                            .shade500,
                                      ),

                                      const SizedBox(
                                        width: 5,
                                      ),

                                      Text(
                                        'Secure password recovery with BookIt',
                                        style:
                                            TextStyle(
                                          fontSize: 11,
                                          color: Colors
                                              .grey
                                              .shade500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        // =======================================
                        // BOTTOM TEXT
                        // =======================================

                        const Text(
                          'Book trusted services with ease.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight:
                                FontWeight.w500,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 5,
                                offset: Offset(0, 1),
                              ),
                            ],
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
    );
  }
}