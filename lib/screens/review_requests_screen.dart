import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/plan_request_model.dart';
import '../services/auth_service.dart';

class ReviewRequestsScreen extends StatelessWidget {
  final bool embedded;
  const ReviewRequestsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF050811) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0D1527) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05);

    final content = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: StreamBuilder<List<PlanRequestModel>>(
          stream: auth.streamPlanRequests(pendingOnly: false),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE)));
            }

            final requests = snapshot.data ?? [];
            if (requests.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inbox_rounded, size: 56, color: textSecondary.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        'No Plan Requests Yet',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'When users apply for Pro or Ultra plans, they will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final req = requests[index];
                return _buildRequestCard(context, auth, req, cardBg, borderColor, textPrimary, textSecondary, isDark);
              },
            );
          },
        ),
      ),
    );

    if (embedded) {
      return Container(
        color: bgColor,
        child: content,
      );
    }

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.15) : Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.mark_email_unread_rounded,
                  color: isDark ? const Color(0xFF00F2FE) : Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Review Plan Requests',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
      body: content,
    );
  }

  Widget _buildRequestCard(
    BuildContext context,
    AuthService auth,
    PlanRequestModel req,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    Color planBadgeColor;
    if (req.requestedPlan.toLowerCase() == 'ultra') {
      planBadgeColor = const Color(0xFFFFB300);
    } else {
      planBadgeColor = const Color(0xFF00F2FE);
    }

    final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(req.requestedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: req.isPending ? (isDark ? const Color(0xFF00F2FE) : Colors.black.withValues(alpha: 0.08)) : borderColor,
          width: 1.0,
        ),
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
          // Header: User & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.black,
                      child: Text(
                        req.userName.isNotEmpty ? req.userName[0].toUpperCase() : 'U',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            req.userName,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                          ),
                          Text(
                            req.userEmail,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildStatusChip(req.status),
            ],
          ),
          const SizedBox(height: 12),

          // Plan Upgrade Details Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      req.currentPlan.toUpperCase(),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textSecondary),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: textSecondary),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: planBadgeColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: planBadgeColor),
                      ),
                      child: Text(
                        req.requestedPlan.toUpperCase(),
                        style: TextStyle(
                          color: planBadgeColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'BDT ${req.priceBDT}',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Timestamp
          Text(
            'Requested: $dateStr',
            style: TextStyle(fontSize: 10, color: textSecondary),
          ),

          // Action Buttons (Only when pending)
          if (req.isPending) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                // Reject Button
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await auth.rejectPlanRequest(req.id);
                      messenger.showSnackBar(
                        const SnackBar(content: Text('Request rejected')),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),

                // Accept & Activate Button
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.greenAccent.shade700,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text(
                      'Accept & Activate',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12),
                    ),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await auth.approvePlanRequest(req);
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text('${req.userName}\'s ${req.requestedPlan.toUpperCase()} plan is now active!'),
                          backgroundColor: Colors.greenAccent.shade700,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;
    String label;

    switch (status.toLowerCase()) {
      case 'approved':
        color = Colors.greenAccent.shade700;
        icon = Icons.check_circle_rounded;
        label = 'ACTIVATED';
        break;
      case 'rejected':
        color = Colors.redAccent;
        icon = Icons.cancel_rounded;
        label = 'REJECTED';
        break;
      default:
        color = Colors.amber.shade700;
        icon = Icons.hourglass_top_rounded;
        label = 'PENDING';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
