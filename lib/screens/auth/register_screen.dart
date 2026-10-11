import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // =========================================================
  // DISPOSE
  // =========================================================

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================================================
  // REGISTER
  // =========================================================

  Future<void> _register() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authService.register(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );

      if (!mounted) return;

      if (user != null) {
        // After successful registration,
        // go to the email verification screen.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => const VerifyEmailScreen(),
          ),
          (route) => false,
        );
      }
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
  // INPUT DECORATION
  // =========================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      prefixIcon: Icon(
        icon,
        color: secondaryText,
      ),

      suffixIcon: suffixIcon,

      filled: true,
      fillColor: const Color(0xFFF7FAF8),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),

      hintStyle: const TextStyle(
        color: Color(0xFF9AA49F),
        fontSize: 14,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: BorderSide.none,
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Color(0xFFE1E8E4),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: primaryGreen,
          width: 1.5,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.3,
        ),
      ),
    );
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
          // BACKGROUND IMAGE
          // =====================================================

          Positioned.fill(
            child: Image.asset(
              'assets/auth/booked_background.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.center,
            ),
          ),

          // =====================================================
          // LIGHT OVERLAY
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
                final isDesktop = constraints.maxWidth >= 700;

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),

                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 40 : 18,
                    vertical: 18,
                  ),

                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 36,
                    ),

                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.center,

                      children: [
                        // =========================================
                        // BOOKIT BRAND
                        // =========================================

                        Align(
                          alignment: Alignment.topLeft,

                          child: Row(
                            mainAxisSize: MainAxisSize.min,

                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                padding:
                                    const EdgeInsets.all(3),

                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius:
                                      BorderRadius.circular(12),

                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black
                                          .withValues(
                                        alpha: 0.15,
                                      ),
                                      blurRadius: 10,
                                      offset:
                                          const Offset(0, 4),
                                    ),
                                  ],
                                ),

                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.circular(9),

                                  child: Image.asset(
                                    'assets/icon/bookit_app_icon.png',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 10),

                              const Text(
                                'BookIt',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight:
                                      FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black54,
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

                        // =========================================
                        // SPACE FOR BACKGROUND LOGO
                        // =========================================

                        SizedBox(
                          height: isDesktop ? 85 : 55,
                        ),

                        // =========================================
                        // REGISTER CARD
                        // =========================================

                        Align(
                          alignment: Alignment.center,

                          child: ConstrainedBox(
                            constraints:
                                const BoxConstraints(
                              maxWidth: 430,
                            ),

                            child: Container(
                              width: double.infinity,

                              padding:
                                  const EdgeInsets.fromLTRB(
                                24,
                                24,
                                24,
                                20,
                              ),

                              decoration: BoxDecoration(
                                color: Colors.white
                                    .withValues(
                                  alpha: 0.96,
                                ),

                                borderRadius:
                                    BorderRadius.circular(
                                  24,
                                ),

                                border: Border.all(
                                  color: Colors.white
                                      .withValues(
                                    alpha: 0.9,
                                  ),
                                ),

                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withValues(
                                      alpha: 0.20,
                                    ),
                                    blurRadius: 28,
                                    offset:
                                        const Offset(0, 12),
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
                                    // ===========================
                                    // TITLE
                                    // ===========================

                                    const Text(
                                      'Create your account ✨',
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight:
                                            FontWeight.w800,
                                        color: darkText,
                                        letterSpacing: -0.4,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    const Text(
                                      'Join BookIt and start booking services',
                                      style: TextStyle(
                                        fontSize: 13.5,
                                        color:
                                            secondaryText,
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 20,
                                    ),

                                    // ===========================
                                    // FULL NAME
                                    // ===========================

                                    const Text(
                                      'Full name',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextFormField(
                                      controller:
                                          _nameController,

                                      textCapitalization:
                                          TextCapitalization
                                              .words,

                                      textInputAction:
                                          TextInputAction.next,

                                      decoration:
                                          _inputDecoration(
                                        hint:
                                            'Enter your full name',
                                        icon:
                                            Icons.person_outline,
                                      ),

                                      validator: (value) {
                                        final name =
                                            value?.trim() ??
                                                '';

                                        if (name.isEmpty) {
                                          return 'Please enter your name';
                                        }

                                        if (name.length <
                                            2) {
                                          return 'Name is too short';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                      height: 13,
                                    ),

                                    // ===========================
                                    // EMAIL
                                    // ===========================

                                    const Text(
                                      'Email address',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextFormField(
                                      controller:
                                          _emailController,

                                      keyboardType:
                                          TextInputType
                                              .emailAddress,

                                      textInputAction:
                                          TextInputAction.next,

                                      autocorrect: false,

                                      decoration:
                                          _inputDecoration(
                                        hint:
                                            'you@example.com',
                                        icon:
                                            Icons.email_outlined,
                                      ),

                                      validator: (value) {
                                        final email =
                                            value?.trim() ??
                                                '';

                                        if (email.isEmpty) {
                                          return 'Please enter your email';
                                        }

                                        if (!email.contains(
                                              '@',
                                            ) ||
                                            !email.contains(
                                              '.',
                                            )) {
                                          return 'Please enter a valid email';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                      height: 13,
                                    ),

                                    // ===========================
                                    // PASSWORD
                                    // ===========================

                                    const Text(
                                      'Password',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextFormField(
                                      controller:
                                          _passwordController,

                                      obscureText:
                                          _obscurePassword,

                                      textInputAction:
                                          TextInputAction.next,

                                      decoration:
                                          _inputDecoration(
                                        hint:
                                            'Create a password',
                                        icon:
                                            Icons.lock_outline,

                                        suffixIcon:
                                            IconButton(
                                          tooltip:
                                              _obscurePassword
                                                  ? 'Show password'
                                                  : 'Hide password',

                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons
                                                    .visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            color:
                                                secondaryText,
                                          ),

                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                        ),
                                      ),

                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return 'Please create a password';
                                        }

                                        if (value.length <
                                            6) {
                                          return 'Password must be at least 6 characters';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                      height: 13,
                                    ),

                                    // ===========================
                                    // CONFIRM PASSWORD
                                    // ===========================

                                    const Text(
                                      'Confirm password',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight:
                                            FontWeight.w600,
                                        color: darkText,
                                      ),
                                    ),

                                    const SizedBox(height: 6),

                                    TextFormField(
                                      controller:
                                          _confirmPasswordController,

                                      obscureText:
                                          _obscureConfirmPassword,

                                      textInputAction:
                                          TextInputAction.done,

                                      onFieldSubmitted: (_) {
                                        if (!_isLoading) {
                                          _register();
                                        }
                                      },

                                      decoration:
                                          _inputDecoration(
                                        hint:
                                            'Re-enter your password',
                                        icon:
                                            Icons.lock_outline,

                                        suffixIcon:
                                            IconButton(
                                          tooltip:
                                              _obscureConfirmPassword
                                                  ? 'Show password'
                                                  : 'Hide password',

                                          icon: Icon(
                                            _obscureConfirmPassword
                                                ? Icons
                                                    .visibility_outlined
                                                : Icons
                                                    .visibility_off_outlined,
                                            color:
                                                secondaryText,
                                          ),

                                          onPressed: () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                        ),
                                      ),

                                      validator: (value) {
                                        if (value == null ||
                                            value.isEmpty) {
                                          return 'Please confirm your password';
                                        }

                                        if (value !=
                                            _passwordController
                                                .text) {
                                          return 'Passwords do not match';
                                        }

                                        return null;
                                      },
                                    ),

                                    const SizedBox(
                                      height: 18,
                                    ),

                                    // ===========================
                                    // CREATE ACCOUNT BUTTON
                                    // ===========================

                                    SizedBox(
                                      height: 51,

                                      child:
                                          ElevatedButton(
                                        onPressed:
                                            _isLoading
                                                ? null
                                                : _register,

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
                                            : const Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .center,
                                                children: [
                                                  Text(
                                                    'Create Account',
                                                    style:
                                                        TextStyle(
                                                      fontSize:
                                                          15.5,
                                                      fontWeight:
                                                          FontWeight
                                                              .w700,
                                                    ),
                                                  ),
                                                  SizedBox(
                                                    width: 8,
                                                  ),
                                                  Icon(
                                                    Icons
                                                        .arrow_forward_rounded,
                                                    size: 19,
                                                  ),
                                                ],
                                              ),
                                      ),
                                    ),

                                    const SizedBox(
                                      height: 15,
                                    ),

                                    // ===========================
                                    // LOGIN
                                    // ===========================

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,

                                      children: [
                                        const Flexible(
                                          child: Text(
                                            'Already have an account?',
                                            overflow:
                                                TextOverflow
                                                    .ellipsis,
                                            style: TextStyle(
                                              fontSize: 13,
                                              color:
                                                  secondaryText,
                                            ),
                                          ),
                                        ),

                                        TextButton(
                                          onPressed:
                                              _isLoading
                                                  ? null
                                                  : () {
                                                      Navigator
                                                          .pushReplacement(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder:
                                                              (_) =>
                                                                  const LoginScreen(),
                                                        ),
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

                                    // ===========================
                                    // SECURITY
                                    // ===========================

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,

                                      children: [
                                        Icon(
                                          Icons
                                              .verified_user_outlined,
                                          size: 14,
                                          color:
                                              Colors.grey
                                                  .shade500,
                                        ),

                                        const SizedBox(
                                          width: 5,
                                        ),

                                        Text(
                                          'Your information is secure with BookIt',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.grey
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
                        ),

                        const SizedBox(height: 16),

                        // =========================================
                        // BOTTOM TEXT
                        // =========================================

                        const Text(
                          'Book trusted services with ease.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
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