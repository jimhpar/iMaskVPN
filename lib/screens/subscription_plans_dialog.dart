import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';

class SubscriptionPlansDialog extends StatefulWidget {
  const SubscriptionPlansDialog({super.key});

  @override
  State<SubscriptionPlansDialog> createState() => _SubscriptionPlansDialogState();
}

class _SubscriptionPlansDialogState extends State<SubscriptionPlansDialog> {
  String? _selectedPlan;
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final userProfile = auth.userProfile;
    final currentPlan = userProfile?.plan.toLowerCase() ?? 'free';
    final isAdmin = userProfile?.isAdmin ?? false;
    _selectedPlan ??= currentPlan;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? const Color(0xFF0D121D) : Colors.white;
    final cardBg = isDark ? const Color(0xFF131A29) : const Color(0xFFF8FAFC);
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF4A5568);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.black;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: isDark ? 1.0 : 2.0),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Subscription Plans',
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select a plan to submit an upgrade request',
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Plans list
              Expanded(
                child: ListView(
                  children: [
                    _buildPlanCard(
                      id: 'free',
                      title: 'Free Plan',
                      price: 'Free',
                      priceSub: 'Forever',
                      badge: 'BASIC',
                      badgeColor: Colors.blueGrey,
                      continuousLimit: '1 Hour continuous connection',
                      weeklyLimit: '5 Hours weekly usage',
                      speeds: 'Standard speed network',
                      servers: 'Standard global locations',
                      accentColor: Colors.cyan,
                      isSelected: _selectedPlan == 'free',
                      isCurrent: currentPlan == 'free',
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      id: 'pro',
                      title: 'Pro Plan',
                      price: 'BDT 99',
                      priceSub: '/ month',
                      badge: 'POPULAR [P]',
                      badgeColor: const Color(0xFF00C6FF),
                      continuousLimit: '3 Hours continuous session',
                      weeklyLimit: '15 Hours weekly usage',
                      speeds: 'Ultra high-speed dedicated tunnels',
                      servers: 'All 75 Countries + VIP fast routes',
                      accentColor: const Color(0xFF00F2FE),
                      isSelected: _selectedPlan == 'pro',
                      isCurrent: currentPlan == 'pro',
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 12),
                    _buildPlanCard(
                      id: 'ultra',
                      title: 'Ultra Plan',
                      price: 'BDT 499',
                      priceSub: '/ month',
                      badge: 'VIP UNLIMITED [U]',
                      badgeColor: const Color(0xFFFFB300),
                      continuousLimit: 'Unlimited continuous session',
                      weeklyLimit: 'Unlimited weekly usage (No caps)',
                      speeds: 'Maximum Gbps throughput',
                      servers: 'Full 75+ Dedicated WireGuard nodes',
                      accentColor: const Color(0xFFFFB300),
                      isSelected: _selectedPlan == 'ultra',
                      isCurrent: currentPlan == 'ultra',
                      cardBg: cardBg,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Apply / Request Button
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                    foregroundColor: isDark ? const Color(0xFF070A10) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: (_isSaving || _selectedPlan == currentPlan)
                      ? null
                      : () async {
                          setState(() => _isSaving = true);

                          if (isAdmin || _selectedPlan == 'free') {
                            await auth.applyPlan(_selectedPlan!);
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Plan updated to ${_selectedPlan!.toUpperCase()} successfully!'),
                                backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            await auth.submitPlanRequest(_selectedPlan!);
                            if (!mounted) return;
                            setState(() => _isSaving = false);
                            Navigator.pop(context);
                            _showSubmittedDialog(context, _selectedPlan!);
                          }
                        },
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _selectedPlan == currentPlan
                              ? 'Current Active Plan'
                              : (isAdmin
                                  ? 'Activate ${_selectedPlan?.toUpperCase()} (Admin Instant)'
                                  : 'Submit ${_selectedPlan?.toUpperCase()} Request to Admin'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmittedDialog(BuildContext context, String plan) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final price = plan.toLowerCase() == 'ultra' ? '499' : '99';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 24),
            const SizedBox(width: 8),
            Text(
              'Request Submitted!',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        content: Text(
          'Your upgrade request for ${plan.toUpperCase()} plan (BDT $price) has been sent to Admin for review. Once accepted, your account will be upgraded immediately!',
          style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF334155), fontSize: 13),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
              foregroundColor: isDark ? Colors.black : Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String priceSub,
    required String badge,
    required Color badgeColor,
    required String continuousLimit,
    required String weeklyLimit,
    required String speeds,
    required String servers,
    required Color accentColor,
    required bool isSelected,
    required bool isCurrent,
    required Color cardBg,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    final activeBorderColor = isDark ? accentColor : Colors.black;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected
                ? activeBorderColor
                : (isCurrent
                    ? (isDark ? Colors.white30 : Colors.black)
                    : (isDark ? Colors.white12 : Colors.grey.shade300)),
            width: isSelected ? 2.5 : (isDark ? 1.0 : 1.5),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (isDark ? accentColor : Colors.black).withValues(alpha: 0.15),
                    blurRadius: 16,
                    spreadRadius: 2,
                  )
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: isDark ? 0.15 : 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: isDark ? badgeColor : Colors.black,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text(
                      'ACTIVE',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  price,
                  style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: isDark ? accentColor : Colors.black,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  priceSub,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _featureItem(Icons.timer_outlined, continuousLimit, textSecondary, isDark ? const Color(0xFF00F2FE) : Colors.black),
            const SizedBox(height: 4),
            _featureItem(Icons.calendar_month_outlined, weeklyLimit, textSecondary, isDark ? const Color(0xFF00F2FE) : Colors.black),
            const SizedBox(height: 4),
            _featureItem(Icons.speed_rounded, speeds, textSecondary, isDark ? const Color(0xFF00F2FE) : Colors.black),
            const SizedBox(height: 4),
            _featureItem(Icons.public_rounded, servers, textSecondary, isDark ? const Color(0xFF00F2FE) : Colors.black),
          ],
        ),
      ),
    );
  }

  Widget _featureItem(IconData icon, String text, Color textColor, Color iconColor) {
    return Row(
      children: [
        Icon(icon, size: 14, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: textColor),
          ),
        ),
      ],
    );
  }
}
