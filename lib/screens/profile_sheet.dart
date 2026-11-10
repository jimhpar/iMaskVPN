import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../services/vpn_service.dart';
import 'admin_console_screen.dart';
import 'review_requests_screen.dart';
import 'subscription_plans_dialog.dart';

class ProfileSheet extends StatelessWidget {
  const ProfileSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final themeService = Provider.of<ThemeService>(context);
    final userProfile = auth.userProfile;
    final user = auth.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sheetBg = isDark ? const Color(0xFF0D121D) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF131A29) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final defaultBorder = isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05);

    final plan = userProfile?.plan.toLowerCase() ?? 'free';
    final badgeLetter = userProfile?.planBadgeLetter ?? '';
    final isAdmin = userProfile?.isAdmin ?? false;
    final isSuper = userProfile?.isSuperAdmin ?? false;

    Color planColor;
    if (plan == 'ultra') {
      planColor = const Color(0xFFFFB300);
    } else if (plan == 'pro') {
      planColor = const Color(0xFF00F2FE);
    } else {
      planColor = isDark ? Colors.blueGrey : Colors.black54;
    }

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: defaultBorder, width: 1.0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Grab handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // User Header Row (Avatar, Name, Edit, Plan)
              Row(
                children: [
                  // Avatar with bottom badge
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDark ? const Color(0xFF131A29) : Colors.black,
                          border: Border.all(
                            color: isDark ? (planColor) : Colors.black,
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (userProfile?.displayName.isNotEmpty ?? false)
                                ? userProfile!.displayName[0].toUpperCase()
                                : (user?.email?.isNotEmpty ?? false)
                                    ? user!.email![0].toUpperCase()
                                    : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      if (badgeLetter.isNotEmpty)
                        Positioned(
                          bottom: -2,
                          right: -2,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: planColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: sheetBg, width: 2),
                            ),
                            child: Center(
                              child: Text(
                                badgeLetter,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(width: 14),

                  // Name & email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userProfile?.displayName ?? 'iMask Member',
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 16),
                              color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                              tooltip: 'Edit Name',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showEditNameDialog(context, auth),
                            ),
                          ],
                        ),
                        Text(
                          user?.email ?? 'member@imask.vpn',
                          style: TextStyle(fontSize: 12, color: textSecondary),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: planColor.withValues(alpha: isDark ? 0.15 : 0.2),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: planColor),
                              ),
                              child: Text(
                                'PLAN: ${userProfile?.planTitle.toUpperCase() ?? "FREE"}',
                                style: TextStyle(
                                  color: isDark ? planColor : Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (isAdmin) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                                ),
                                child: Text(
                                  isSuper ? 'SUPERADMIN' : 'ADMIN',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- 1. SUBSCRIPTION PLAN TILE ---
              _buildTile(
                icon: Icons.workspace_premium_rounded,
                iconColor: planColor,
                title: 'Subscription Plan',
                subtitle: 'Active: ${userProfile?.planTitle ?? "Free"} • Free / Pro / Ultra',
                trailing: Text(
                  'Manage >',
                  style: TextStyle(
                    color: isDark ? planColor : Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                defaultBorder: defaultBorder,
                isDark: isDark,
                onTap: () {
                  Navigator.pop(context);
                  showDialog(
                    context: context,
                    builder: (ctx) => const SubscriptionPlansDialog(),
                  );
                },
              ),
              const SizedBox(height: 12),

              // --- 2. THEME SELECTOR ---
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: defaultBorder, width: 1.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 3),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.palette_outlined, size: 20, color: isDark ? const Color(0xFF00F2FE) : Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          'App Theme (Contrast Mode)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: textPrimary, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _themeOption(
                            label: 'System',
                            icon: Icons.settings_brightness_rounded,
                            isSelected: themeService.themeMode == ThemeMode.system,
                            onTap: () => themeService.setThemeMode(ThemeMode.system),
                            textPrimary: textPrimary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _themeOption(
                            label: 'Light (B&W)',
                            icon: Icons.light_mode_rounded,
                            isSelected: themeService.themeMode == ThemeMode.light,
                            onTap: () => themeService.setThemeMode(ThemeMode.light),
                            textPrimary: textPrimary,
                            isDark: isDark,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _themeOption(
                            label: 'Dark (Cyber)',
                            icon: Icons.dark_mode_rounded,
                            isSelected: themeService.themeMode == ThemeMode.dark,
                            onTap: () => themeService.setThemeMode(ThemeMode.dark),
                            textPrimary: textPrimary,
                            isDark: isDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // --- 3. CHANGE PASSWORD ---
              _buildTile(
                icon: Icons.lock_reset_rounded,
                iconColor: Colors.amber.shade700,
                title: 'Change Password',
                subtitle: 'Update or reset account login security',
                trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                cardBg: cardBg,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
                defaultBorder: defaultBorder,
                isDark: isDark,
                onTap: () => _showChangePasswordDialog(context, auth),
              ),

              // --- 4. ADMIN CONSOLE, REVIEW REQUESTS & MANAGE PLANS (IF ADMIN) ---
              if (isAdmin) ...[
                const SizedBox(height: 18),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      const Icon(Icons.shield_rounded, size: 14, color: Colors.redAccent),
                      const SizedBox(width: 6),
                      Text(
                        isSuper ? 'SUPERADMINISTRATION' : 'ADMINISTRATION CONSOLE',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.redAccent,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Option A: Admin Console
                _buildTile(
                  icon: Icons.dashboard_customize_rounded,
                  iconColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                  title: 'Admin Console',
                  subtitle: 'Server node telemetry, metrics & revenue',
                  trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  defaultBorder: defaultBorder,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminConsoleScreen(initialTabIndex: 0)),
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Option B: Review Requests (with pending badge count!)
                StreamBuilder<int>(
                  stream: auth.streamPendingRequestsCount(),
                  builder: (context, snapshot) {
                    final pendingCount = snapshot.data ?? 0;
                    return _buildTile(
                      icon: Icons.mark_email_unread_rounded,
                      iconColor: Colors.amber.shade700,
                      title: 'Review Requests',
                      subtitle: pendingCount > 0
                          ? '$pendingCount Pending user plan approval(s)'
                          : 'Review and approve user upgrade requests',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (pendingCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade700,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$pendingCount PENDING',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded, color: textSecondary),
                        ],
                      ),
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      defaultBorder: pendingCount > 0 ? Colors.amber.shade700 : defaultBorder,
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ReviewRequestsScreen()),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 10),

                // Option C: Manage Plans & Users
                _buildTile(
                  icon: Icons.manage_accounts_rounded,
                  iconColor: const Color(0xFFFFB300),
                  title: 'Manage Plans & Users',
                  subtitle: 'User list, add/edit/delete, assign Free/Pro/Ultra',
                  trailing: Icon(Icons.chevron_right_rounded, color: textSecondary),
                  cardBg: cardBg,
                  textPrimary: textPrimary,
                  textSecondary: textSecondary,
                  defaultBorder: defaultBorder,
                  isDark: isDark,
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminConsoleScreen(initialTabIndex: 1)),
                    );
                  },
                ),
              ],

              const SizedBox(height: 24),

              // --- 5. LOGOUT BUTTON ---
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text('Sign Out from iMask', style: TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    Navigator.pop(context);
                    Provider.of<VpnService>(context, listen: false).resetToDefault();
                    auth.signOut();
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required Color defaultBorder,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: defaultBorder, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
              blurRadius: 14,
              offset: const Offset(0, 3),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: isDark ? 0.15 : 0.1),
                borderRadius: BorderRadius.circular(10),
                border: isDark ? null : Border.all(color: iconColor.withValues(alpha: 0.3)),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: textSecondary)),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }

  Widget _themeOption({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textPrimary,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.2) : Colors.black)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? (isDark ? const Color(0xFF00F2FE) : Colors.black) : (isDark ? Colors.white12 : Colors.grey.shade400),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? (isDark ? const Color(0xFF00F2FE) : Colors.white)
                  : textPrimary.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? (isDark ? const Color(0xFF00F2FE) : Colors.white) : textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditNameDialog(BuildContext context, AuthService auth) {
    final ctrl = TextEditingController(text: auth.userProfile?.displayName ?? '');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
        ),
        title: Text(
          'Update Display Name',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Enter your name',
            hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              if (ctrl.text.trim().isNotEmpty) {
                await auth.updateDisplayName(ctrl.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, AuthService auth) {
    final newPassCtrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
        ),
        title: Text(
          'Change Password',
          style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter a new password or send a reset link to your email.',
              style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(0xFF334155)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: TextStyle(color: isDark ? Colors.white : Colors.black),
              decoration: InputDecoration(
                labelText: 'New Password (min 6 characters)',
                labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await auth.sendPasswordResetEmail();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Password reset email sent! Check your inbox.'),
                    backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                  ),
                );
              }
            },
            child: Text('Email Reset Link', style: TextStyle(color: isDark ? const Color(0xFF00F2FE) : Colors.black)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () async {
              if (newPassCtrl.text.trim().length >= 6) {
                final success = await auth.changePassword(newPassCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? 'Password updated successfully!' : 'Password update failed.'),
                      backgroundColor: success ? Colors.green : Colors.redAccent,
                    ),
                  );
                }
              }
            },
            child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
