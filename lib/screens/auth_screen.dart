import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  final _signInFormKey = GlobalKey<FormState>();

  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();
  final _signUpFormKey = GlobalKey<FormState>();

  bool _obscureSignInPassword = true;
  bool _obscureSignUpPassword = true;

  @override
  void dispose() {
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  void _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signInWithEmail(
      _signInEmailController.text,
      _signInPasswordController.text,
    );
  }

  void _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signUpWithEmail(
      _signUpEmailController.text,
      _signUpPasswordController.text,
      _signUpNameController.text.isEmpty ? 'iMask Member' : _signUpNameController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.themeMode == ThemeMode.dark;

    final bgColor = isDark ? const Color(0xFF090D16) : Colors.white;
    final cardBg = isDark ? const Color(0xFF131A29) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top Bar with Theme Toggle Switch
                    Align(
                      alignment: Alignment.topRight,
                      child: GestureDetector(
                        onTap: () {
                          themeService.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF131A29) : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                size: 16,
                                color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isDark ? 'Light Mode' : 'Dark Mode',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // App Logo (Borderless)
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? const Color(0xFF00F2FE) : Colors.black).withValues(alpha: isDark ? 0.35 : 0.12),
                            blurRadius: 28,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 86,
                          height: 86,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                            child: const Icon(
                              Icons.shield_rounded,
                              size: 46,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'iMask VPN',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ultra-Fast & Encrypted Global Browsing',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 26),

                    // Card with Soft Drop Shadow
                    Container(
                      padding: const EdgeInsets.all(26.0),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // TabBar Header
                          Container(
                            height: 44,
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF0C111C) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TabBar(
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                color: isDark ? const Color(0xFF1E273A) : Colors.black,
                                borderRadius: BorderRadius.circular(10),
                                border: isDark
                                    ? Border.all(color: const Color(0xFF00F2FE).withValues(alpha: 0.3))
                                    : null,
                              ),
                              labelColor: isDark ? const Color(0xFF00F2FE) : Colors.white,
                              unselectedLabelColor: isDark ? Colors.white54 : const Color(0xFF64748B),
                              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15),
                              tabs: const [
                                Tab(text: 'Sign In'),
                                Tab(text: 'Sign Up'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Error message
                          if (auth.errorMessage != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      auth.errorMessage!,
                                      style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Tab Views
                          SizedBox(
                            height: 230,
                            child: TabBarView(
                              children: [
                                // 1. Sign In Form
                                Form(
                                  key: _signInFormKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _signInEmailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration(
                                          hintText: 'Email address',
                                          prefixIcon: Icons.email_outlined,
                                          isDark: isDark,
                                        ),
                                        validator: (val) =>
                                            val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                      ),
                                      const SizedBox(height: 14),
                                      TextFormField(
                                        controller: _signInPasswordController,
                                        obscureText: _obscureSignInPassword,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration(
                                          hintText: 'Password',
                                          prefixIcon: Icons.lock_outline,
                                          isDark: isDark,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureSignInPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscureSignInPassword = !_obscureSignInPassword),
                                          ),
                                        ),
                                        validator: (val) =>
                                            val == null || val.length < 6 ? 'Password is too short' : null,
                                      ),
                                      const Spacer(),
                                      _buildGradientButton(
                                        title: 'Sign In to iMask',
                                        isLoading: auth.isLoading,
                                        onPressed: _handleSignIn,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),

                                // 2. Sign Up Form
                                Form(
                                  key: _signUpFormKey,
                                  child: Column(
                                    children: [
                                      TextFormField(
                                        controller: _signUpNameController,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration(
                                          hintText: 'Full Name',
                                          prefixIcon: Icons.person_outline,
                                          isDark: isDark,
                                        ),
                                        validator: (val) =>
                                            val == null || val.isEmpty ? 'Enter your name' : null,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _signUpEmailController,
                                        keyboardType: TextInputType.emailAddress,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration(
                                          hintText: 'Email address',
                                          prefixIcon: Icons.email_outlined,
                                          isDark: isDark,
                                        ),
                                        validator: (val) =>
                                            val == null || !val.contains('@') ? 'Enter a valid email' : null,
                                      ),
                                      const SizedBox(height: 10),
                                      TextFormField(
                                        controller: _signUpPasswordController,
                                        obscureText: _obscureSignUpPassword,
                                        style: TextStyle(color: textPrimary),
                                        decoration: _inputDecoration(
                                          hintText: 'Create Password',
                                          prefixIcon: Icons.lock_outline,
                                          isDark: isDark,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureSignUpPassword
                                                  ? Icons.visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: textSecondary,
                                              size: 20,
                                            ),
                                            onPressed: () => setState(
                                                () => _obscureSignUpPassword = !_obscureSignUpPassword),
                                          ),
                                        ),
                                        validator: (val) =>
                                            val == null || val.length < 6 ? 'Minimum 6 characters' : null,
                                      ),
                                      const Spacer(),
                                      _buildGradientButton(
                                        title: 'Create Account',
                                        isLoading: auth.isLoading,
                                        onPressed: _handleSignUp,
                                        isDark: isDark,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('OR', style: TextStyle(color: textSecondary, fontSize: 11)),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white12 : Colors.black12)),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Google Sign-In
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.15),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: isDark ? const Color(0xFF0C111C) : const Color(0xFFF8FAFC),
                            ),
                            icon: Image.network(
                              'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                              width: 18,
                              height: 18,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.g_mobiledata,
                                size: 24,
                                color: Colors.blue,
                              ),
                            ),
                            label: Text(
                              'Continue with Google',
                              style: TextStyle(
                                color: textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            onPressed: auth.isLoading
                                ? null
                                : () => auth.signInWithGoogle(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientButton({
    required String title,
    required bool isLoading,
    required VoidCallback onPressed,
    required bool isDark,
  }) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.zero,
        backgroundColor: isDark ? Colors.transparent : Colors.black,
        elevation: isDark ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Ink(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(colors: [Color(0xFF00F2FE), Color(0xFF4FACFE)])
              : null,
          color: isDark ? null : Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                )
              : Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.black : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: TextStyle(color: isDark ? Colors.white38 : const Color(0xFF94A3B8), fontSize: 13),
      prefixIcon: Icon(prefixIcon, color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 18),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: isDark ? const Color(0xFF0B101C) : const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: isDark ? const Color(0xFF00F2FE) : Colors.black, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }
}
