import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'review_requests_screen.dart';

class AdminConsoleScreen extends StatefulWidget {
  final int initialTabIndex;
  const AdminConsoleScreen({super.key, this.initialTabIndex = 0});

  @override
  State<AdminConsoleScreen> createState() => _AdminConsoleScreenState();
}

class _AdminConsoleScreenState extends State<AdminConsoleScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF050811) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF0D1527) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white70 : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05);

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
                child: Icon(Icons.admin_panel_settings_rounded, color: isDark ? const Color(0xFF00F2FE) : Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'iMask Admin Hub',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary),
              ),
            ],
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: TabBar(
                controller: _tabController,
                indicatorColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                labelColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                unselectedLabelColor: textSecondary,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  const Tab(icon: Icon(Icons.dashboard_rounded), text: 'Console'),
                  Tab(
                    icon: StreamBuilder<int>(
                      stream: auth.streamPendingRequestsCount(),
                      builder: (context, snapshot) {
                        final count = snapshot.data ?? 0;
                        return Badge(
                          isLabelVisible: count > 0,
                          label: Text('$count'),
                          backgroundColor: Colors.amber.shade700,
                          child: const Icon(Icons.mark_email_unread_rounded),
                        );
                      },
                    ),
                    text: 'Review Requests',
                  ),
                  const Tab(icon: Icon(Icons.manage_accounts_rounded), text: 'Manage Users'),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: StreamBuilder<List<UserModel>>(
            stream: auth.streamAllUsers(),
            builder: (context, snapshot) {
              final users = snapshot.data ?? [];
              final isLoading = snapshot.connectionState == ConnectionState.waiting;

              return TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Admin Console Overview
                  _buildOverviewTab(users, isLoading, cardBg, borderColor, textPrimary, textSecondary, isDark),

                  // Tab 2: Review Requests
                  const ReviewRequestsScreen(embedded: true),

                  // Tab 3: Manage Plans & Users
                  _buildManageUsersTab(users, isLoading, auth, cardBg, borderColor, textPrimary, textSecondary, isDark),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // --- TAB 1: CONSOLE OVERVIEW ---
  Widget _buildOverviewTab(
    List<UserModel> users,
    bool isLoading,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final freeCount = users.where((u) => u.plan == 'free').length;
    final proCount = users.where((u) => u.plan == 'pro').length;
    final ultraCount = users.where((u) => u.plan == 'ultra').length;
    final totalRevenue = (proCount * 99) + (ultraCount * 499);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Dedicated Server Status Card
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor, width: 1.0),
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.greenAccent,
                          boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 8, spreadRadius: 1)],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dedicated Server Node',
                        style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green),
                    ),
                    child: const Text('ONLINE', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _statRow('Server IP:', '129.225.114.149 (Oracle Hyderabad)', textSecondary, textPrimary),
              const SizedBox(height: 4),
              _statRow('Protocol:', 'WireGuard UDP (Port 51820)', textSecondary, textPrimary),
              const SizedBox(height: 4),
              _statRow('Web Dashboard:', 'http://129.225.114.149:51821', textSecondary, isDark ? const Color(0xFF00F2FE) : Colors.black),
              const SizedBox(height: 4),
              _statRow('Capacity / Spec:', 'AMD Always Free • 1 Gbps NIC', textSecondary, textPrimary),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // System & Plan Metrics
        Text(
          'System & Plan Metrics',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary),
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _metricCard('Total Users', '${users.length}', Icons.people_alt_rounded, isDark ? const Color(0xFF00F2FE) : Colors.black, cardBg, borderColor, textPrimary, textSecondary)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Monthly Revenue', 'BDT $totalRevenue', Icons.payments_rounded, Colors.greenAccent.shade700, cardBg, borderColor, textPrimary, textSecondary)),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          children: [
            Expanded(child: _metricCard('Free Users', '$freeCount', Icons.person_outline_rounded, Colors.blueGrey, cardBg, borderColor, textPrimary, textSecondary)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Pro [P]', '$proCount', Icons.verified_user_rounded, const Color(0xFF00C6FF), cardBg, borderColor, textPrimary, textSecondary)),
            const SizedBox(width: 12),
            Expanded(child: _metricCard('Ultra [U]', '$ultraCount', Icons.workspace_premium_rounded, const Color(0xFFFFB300), cardBg, borderColor, textPrimary, textSecondary)),
          ],
        ),
        const SizedBox(height: 20),

        // Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                  foregroundColor: isDark ? const Color(0xFF070A10) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.mark_email_unread_rounded, size: 18),
                label: const Text('Review Requests', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _tabController.animateTo(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: textPrimary,
                  side: BorderSide(color: borderColor, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                label: const Text('Manage Users', style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => _tabController.animateTo(2),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // --- TAB 3: MANAGE USERS & PLANS ---
  Widget _buildManageUsersTab(
    List<UserModel> users,
    bool isLoading,
    AuthService auth,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    final filteredUsers = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return u.displayName.toLowerCase().contains(q) || u.email.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        // Top Toolbar: Search + Add User Button
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(color: textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search by user name or email...',
                    hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                    filled: true,
                    fillColor: cardBg,
                    contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1.0),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: borderColor, width: 1.0),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Add User', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                onPressed: () => _showAddUserDialog(context, auth, isDark),
              ),
            ],
          ),
        ),

        // User count status
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Showing ${filteredUsers.length} Users',
                style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Text(
                'Real-Time Cloud Sync',
                style: TextStyle(color: isDark ? const Color(0xFF00F2FE) : Colors.black, fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Users List
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00F2FE)))
              : filteredUsers.isEmpty
                  ? Center(
                      child: Text(
                        _searchQuery.isEmpty ? 'No users found in database' : 'No matching users found',
                        style: TextStyle(color: textSecondary),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return _buildUserCard(user, auth, cardBg, borderColor, textPrimary, textSecondary, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUserCard(
    UserModel user,
    AuthService auth,
    Color cardBg,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    Color planColor;
    String badgeLetter = user.planBadgeLetter;
    if (user.plan == 'ultra') {
      planColor = const Color(0xFFFFB300);
    } else if (user.plan == 'pro') {
      planColor = const Color(0xFF00F2FE);
    } else {
      planColor = isDark ? Colors.blueGrey : Colors.black;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: isDark ? const Color(0xFF1C2538) : Colors.black,
                child: Text(
                  user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : 'U',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (badgeLetter.isNotEmpty)
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: planColor,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Center(
                      child: Text(
                        badgeLetter,
                        style: TextStyle(color: isDark ? Colors.black : Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        user.displayName,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textPrimary),
                      ),
                    ),
                    if (user.isAdmin) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.redAccent),
                        ),
                        child: Text(
                          user.isSuperAdmin ? 'SUPER' : 'ADMIN',
                          style: const TextStyle(color: Colors.redAccent, fontSize: 8.5, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  user.email,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: textSecondary),
                ),
              ],
            ),
          ),

          // Plan Selector Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: planColor.withValues(alpha: isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: planColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: user.plan,
                isDense: true,
                dropdownColor: isDark ? const Color(0xFF131A29) : Colors.white,
                icon: Icon(Icons.arrow_drop_down, color: isDark ? planColor : Colors.black, size: 20),
                items: [
                  _dropdownPlanItem('free', 'Free (1hr)', isDark ? Colors.blueGrey : Colors.black),
                  _dropdownPlanItem('pro', 'Pro [P] 99৳', const Color(0xFF00C6FF)),
                  _dropdownPlanItem('ultra', 'Ultra [U] 499৳', const Color(0xFFFFB300)),
                ],
                onChanged: (newPlan) async {
                  if (newPlan != null && newPlan != user.plan) {
                    final messenger = ScaffoldMessenger.of(context);
                    await auth.adminUpdateUser(uid: user.uid, plan: newPlan, role: user.role);
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('${user.displayName}\'s plan updated to ${newPlan.toUpperCase()}!'),
                        backgroundColor: planColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          // Menu button (Edit / Delete)
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert_rounded, color: textSecondary, size: 20),
            color: isDark ? const Color(0xFF131A29) : Colors.white,
            onSelected: (val) {
              if (val == 'edit') {
                _showEditUserDialog(context, auth, user, isDark);
              } else if (val == 'delete') {
                _confirmDeleteUser(context, auth, user, isDark);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'edit',
                child: Row(children: [
                  const Icon(Icons.edit, size: 16, color: Colors.cyan),
                  const SizedBox(width: 8),
                  Text('Edit Details', style: TextStyle(color: textPrimary)),
                ]),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(children: [
                  Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                  SizedBox(width: 8),
                  Text('Delete User', style: TextStyle(color: Colors.redAccent)),
                ]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  DropdownMenuItem<String> _dropdownPlanItem(String value, String label, Color color) {
    return DropdownMenuItem(
      value: value,
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, Color cardBg, Color borderColor, Color textPrimary, Color textSecondary) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w800, color: textPrimary)),
          Text(title, style: TextStyle(fontSize: 11, color: textSecondary)),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color labelColor, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: labelColor)),
        Flexible(
          child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valueColor), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  // --- DIALOGS ---
  void _showAddUserDialog(BuildContext context, AuthService auth, bool isDark) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String selectedPlan = 'pro';
    String selectedRole = 'user';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
          ),
          title: Text('Add New User', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
                TextField(
                  controller: emailCtrl,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'Email Address', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                  decoration: InputDecoration(labelText: 'Password', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Assign Plan:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                    DropdownButton<String>(
                      value: selectedPlan,
                      dropdownColor: isDark ? const Color(0xFF1C2538) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'free', child: Text('Free', style: TextStyle(color: Colors.blueGrey))),
                        DropdownMenuItem(value: 'pro', child: Text('Pro [P] 99৳', style: TextStyle(color: Color(0xFF00C6FF)))),
                        DropdownMenuItem(value: 'ultra', child: Text('Ultra [U] 499৳', style: TextStyle(color: Color(0xFFFFB300)))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedPlan = val!),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Role:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 13)),
                    DropdownButton<String>(
                      value: selectedRole,
                      dropdownColor: isDark ? const Color(0xFF1C2538) : Colors.white,
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(color: Colors.redAccent))),
                      ],
                      onChanged: (val) => setDialogState(() => selectedRole = val!),
                    ),
                  ],
                ),
              ],
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
                if (emailCtrl.text.isNotEmpty && nameCtrl.text.isNotEmpty) {
                  await auth.adminCreateUser(
                    email: emailCtrl.text.trim(),
                    password: passCtrl.text.trim().isEmpty ? '123456' : passCtrl.text.trim(),
                    name: nameCtrl.text.trim(),
                    plan: selectedPlan,
                    role: selectedRole,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                }
              },
              child: const Text('Save User', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditUserDialog(BuildContext context, AuthService auth, UserModel user, bool isDark) {
    final nameCtrl = TextEditingController(text: user.displayName);
    String selectedPlan = user.plan;
    String selectedRole = user.role;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
          ),
          title: Text(
            'Edit User: ${user.displayName}',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black, fontSize: 16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                style: TextStyle(color: isDark ? Colors.white : Colors.black),
                decoration: InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Plan:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  DropdownButton<String>(
                    value: selectedPlan,
                    dropdownColor: isDark ? const Color(0xFF1C2538) : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'free', child: Text('Free', style: TextStyle(color: Colors.blueGrey))),
                      DropdownMenuItem(value: 'pro', child: Text('Pro [P]', style: TextStyle(color: Color(0xFF00C6FF)))),
                      DropdownMenuItem(value: 'ultra', child: Text('Ultra [U]', style: TextStyle(color: Color(0xFFFFB300)))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedPlan = val!),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Role:', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
                  DropdownButton<String>(
                    value: selectedRole,
                    dropdownColor: isDark ? const Color(0xFF1C2538) : Colors.white,
                    items: const [
                      DropdownMenuItem(value: 'user', child: Text('User')),
                      DropdownMenuItem(value: 'admin', child: Text('Admin', style: TextStyle(color: Colors.redAccent))),
                    ],
                    onChanged: (val) => setDialogState(() => selectedRole = val!),
                  ),
                ],
              ),
            ],
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
                await auth.adminUpdateUser(
                  uid: user.uid,
                  plan: selectedPlan,
                  role: selectedRole,
                  name: nameCtrl.text.trim(),
                );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Update', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteUser(BuildContext context, AuthService auth, UserModel user, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF131A29) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? Colors.white12 : Colors.black, width: 2),
        ),
        title: Text('Delete User Account?', style: TextStyle(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete ${user.displayName} (${user.email})? This action cannot be undone.', style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              await auth.adminDeleteUser(user.uid);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
