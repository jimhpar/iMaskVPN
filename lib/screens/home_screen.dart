import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/vpn_service.dart';
import '../widgets/country_flag_widget.dart';
import '../widgets/world_map_radar_widget.dart';
import 'profile_sheet.dart';
import 'subscription_plans_dialog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _lastUserUid;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context);
    final vpn = Provider.of<VpnService>(context);
    final user = auth.currentUser;
    final userProfile = auth.userProfile;

    // Reset to default server if user changes (e.g. logging in as superadmin or switching accounts)
    if (user != null && _lastUserUid != null && _lastUserUid != user.uid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        vpn.resetToDefault();
      });
    }
    _lastUserUid = user?.uid;

    final isConnected = vpn.status == VpnStatus.connected;
    final isConnecting = vpn.status == VpnStatus.connecting;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF050811) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF4A5568);

    // Plan info
    final userPlan = userProfile?.plan.toLowerCase() ?? 'free';
    final userPlanBadge = userProfile?.planBadgeLetter ?? '';
    Color userPlanColor;
    if (userPlan == 'ultra') {
      userPlanColor = const Color(0xFFFFB300);
    } else if (userPlan == 'pro') {
      userPlanColor = const Color(0xFF00F2FE);
    } else {
      userPlanColor = isDark ? Colors.blueGrey : Colors.black;
    }

    // Configure session limits
    final maxMinutes = userProfile?.maxContinuousMinutes ?? 60;
    vpn.setMaxContinuousSeconds(maxMinutes * 60);
    vpn.onSessionLimitReached = () {
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
              const Icon(Icons.timer_off_rounded, color: Colors.amberAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                'Session Limit Reached',
                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ),
          content: Text(
            'Your ${userProfile?.planTitle ?? "Free"} plan allows a maximum continuous connection of ${userProfile?.maxContinuousMinutes == 60 ? "1 hour" : "3 hours"}. Please reconnect or upgrade to Ultra for unlimited continuous sessions.',
            style: TextStyle(color: textSecondary, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Dismiss', style: TextStyle(color: textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showDialog(
                  context: context,
                  builder: (_) => const SubscriptionPlansDialog(),
                );
              },
              child: const Text('Upgrade Plan', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    };

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 14.0),
              child: Column(
                children: [
                  // --- TOP BAR HEADER ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top Left: App Logo & Brand Name
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                width: 42,
                                height: 42,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  width: 42,
                                  height: 42,
                                  color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                                  child: const Icon(Icons.shield_rounded, color: Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'iMask VPN',
                                style: GoogleFonts.outfit(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Ultra-Fast & Encrypted',
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Top Right: User Avatar with Plan Badge (P / U)
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => const ProfileSheet(),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark ? const Color(0xFF131A29) : Colors.black,
                                border: Border.all(
                                  color: isDark ? userPlanColor : Colors.black,
                                  width: 2.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: (isDark ? userPlanColor : Colors.black).withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
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
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            // Plan Badge (P / U) at bottom left
                            if (userPlanBadge.isNotEmpty)
                              Positioned(
                                bottom: -2,
                                left: -2,
                                child: Container(
                                  width: 19,
                                  height: 19,
                                  decoration: BoxDecoration(
                                    color: userPlanColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: scaffoldBg, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: userPlanColor.withValues(alpha: 0.6),
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: Text(
                                      userPlanBadge,
                                      style: TextStyle(
                                        color: userPlan == 'ultra' ? Colors.black : (isDark ? Colors.black : Colors.white),
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // --- WORLD MAP RADAR & FLIGHT ANIMATION WIDGET ---
                  WorldMapRadarWidget(
                    selectedServer: vpn.selectedServer,
                    status: vpn.status,
                  ),

                  const SizedBox(height: 14),

                  // --- BIG HIGH-CONTRAST CONNECT BUTTON ---
                  GestureDetector(
                    onTap: isConnecting ? null : () => vpn.toggleConnection(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 155,
                      height: 155,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected
                            ? (isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.12) : Colors.black)
                            : (isDark ? const Color(0xFF0D1526) : Colors.white),
                        border: Border.all(
                          color: isConnected
                              ? (isDark ? const Color(0xFF00F2FE) : Colors.black)
                              : isConnecting
                                  ? Colors.amber.shade700
                                  : (isDark ? Colors.white12 : Colors.black),
                          width: isConnected ? 3.5 : 2.5,
                        ),
                        boxShadow: [
                          if (isConnected)
                            BoxShadow(
                              color: (isDark ? const Color(0xFF00F2FE) : Colors.black).withValues(alpha: 0.35),
                              blurRadius: 40,
                              spreadRadius: 6,
                            ),
                          if (isConnecting)
                            BoxShadow(
                              color: Colors.amber.withValues(alpha: 0.3),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                        ],
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (isConnecting)
                              SizedBox(
                                width: 44,
                                height: 44,
                                child: CircularProgressIndicator(
                                  color: Colors.amber.shade700,
                                  strokeWidth: 3,
                                ),
                              )
                            else
                              Icon(
                                Icons.power_settings_new_rounded,
                                size: 56,
                                color: isConnected
                                    ? (isDark ? const Color(0xFF00F2FE) : Colors.white)
                                    : (isDark ? Colors.white38 : Colors.black),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              isConnected
                                  ? 'CONNECTED'
                                  : isConnecting
                                      ? 'CONNECTING...'
                                      : 'TAP TO CONNECT',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: isConnected
                                    ? (isDark ? const Color(0xFF00F2FE) : Colors.white)
                                    : isConnecting
                                        ? Colors.amber.shade700
                                        : textPrimary,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- DURATION / UNPROTECTED STATUS ---
                  if (isConnected) ...[
                    Text(
                      vpn.formattedDuration,
                      style: GoogleFonts.sourceCodePro(
                        color: textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock_rounded, size: 14, color: Colors.greenAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Protected IP: ${vpn.selectedServer?.ip}',
                          style: GoogleFonts.inter(
                            color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: isDark ? Colors.white38 : Colors.redAccent),
                        const SizedBox(width: 6),
                        Text(
                          'Your connection is unprotected',
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white38 : Colors.redAccent.shade700,
                            fontWeight: isDark ? FontWeight.normal : FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],

                  const Spacer(),

                  // --- LIVE NETWORK SPEED STATS CARD ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D1527) : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          icon: Icons.arrow_downward_rounded,
                          iconColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                          label: 'DOWNLOAD',
                          value: '${vpn.downloadSpeed} Mbps',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.black12),
                        _buildStatItem(
                          icon: Icons.arrow_upward_rounded,
                          iconColor: isDark ? const Color(0xFF38BDF8) : Colors.black,
                          label: 'UPLOAD',
                          value: '${vpn.uploadSpeed} Mbps',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                        Container(width: 1, height: 30, color: isDark ? Colors.white12 : Colors.black12),
                        _buildStatItem(
                          icon: Icons.network_check_rounded,
                          iconColor: isDark ? Colors.tealAccent : Colors.black,
                          label: 'PING',
                          value: '${vpn.selectedServer?.ping ?? 0} ms',
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // --- COUNTRY / SERVER SELECTOR CARD ---
                  GestureDetector(
                    onTap: () => _showServerSelector(context, vpn, isDark),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0D1527) : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CountryFlagWidget(
                            countryCode: vpn.selectedServer?.countryCode ?? '',
                            fallbackEmoji: vpn.selectedServer?.flagEmoji ?? '🌐',
                            width: 34,
                            height: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      vpn.selectedServer?.country ?? 'Select Country',
                                      style: GoogleFonts.outfit(
                                        color: textPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (vpn.selectedServer?.isVip ?? false) ...[
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.2) : Colors.black,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          'VIP',
                                          style: TextStyle(
                                            color: isDark ? const Color(0xFF00F2FE) : Colors.white,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${vpn.selectedServer?.city} • ${vpn.selectedServer?.protocol}',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.black,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '${vpn.servers.length} Servers',
                                  style: TextStyle(
                                    color: isDark ? const Color(0xFF00F2FE) : Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_right_rounded,
                                  color: isDark ? const Color(0xFF00F2FE) : Colors.white,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(color: textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.outfit(color: textPrimary, fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );
  }

  void _showServerSelector(BuildContext context, VpnService vpn, bool isDark) {
    String selectedContinent = 'All';
    String searchQuery = '';

    final modalBg = isDark ? const Color(0xFF0D1527) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF4A5568);
    final cardBg = isDark ? const Color(0xFF141C2E) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF1E293B) : Colors.black;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: modalBg,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        side: BorderSide(color: borderColor, width: isDark ? 1.0 : 2.0),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final filteredServers = vpn.servers.where((server) {
              final matchesContinent =
                  selectedContinent == 'All' || server.continent == selectedContinent;
              final matchesSearch = searchQuery.isEmpty ||
                  server.country.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  server.city.toLowerCase().contains(searchQuery.toLowerCase());
              return matchesContinent && matchesSearch;
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white24 : Colors.black26,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Count & Live Refresh Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Live Servers (${vpn.servers.length} Available)',
                          style: GoogleFonts.outfit(
                            color: textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Refresh Live VPN Gate Servers',
                        icon: vpn.isFetchingVpnGate
                            ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: isDark ? const Color(0xFF00F2FE) : Colors.black,
                                ),
                              )
                            : Icon(Icons.refresh_rounded, color: textPrimary),
                        onPressed: vpn.isFetchingVpnGate
                            ? null
                            : () async {
                                setModalState(() {});
                                await vpn.fetchVpnGateRelays();
                                if (ctx.mounted) {
                                  setModalState(() {});
                                }
                              },
                      ),
                      IconButton(
                        icon: Icon(Icons.close_rounded, color: textSecondary),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Search Bar
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: isDark ? 1.0 : 1.5),
                    ),
                    child: TextField(
                      style: TextStyle(color: textPrimary, fontSize: 14),
                      decoration: InputDecoration(
                        hintText: 'Search by country or city...',
                        hintStyle: TextStyle(color: textSecondary, fontSize: 13),
                        prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: (value) {
                        setModalState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Continent Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Asia & Pacific',
                        'Europe',
                        'North America',
                        'South America',
                        'Africa',
                      ].map((continent) {
                        final isSelected = selectedContinent == continent;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(continent),
                            selected: isSelected,
                            onSelected: (_) {
                              setModalState(() {
                                selectedContinent = continent;
                              });
                            },
                            selectedColor: isDark ? const Color(0xFF00F2FE) : Colors.black,
                            backgroundColor: cardBg,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF00F2FE) : Colors.black)
                                    : borderColor,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Country List
                  Expanded(
                    child: ListView.separated(
                      itemCount: filteredServers.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final server = filteredServers[index];
                        final isSelected = vpn.selectedServer?.id == server.id;

                        return GestureDetector(
                          onTap: () {
                            vpn.selectServer(server);
                            Navigator.pop(ctx);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))
                                  : cardBg,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? (isDark ? const Color(0xFF00F2FE) : Colors.black)
                                    : (isDark ? Colors.white10 : Colors.black12),
                                width: isSelected ? 2.0 : 1.0,
                              ),
                            ),
                            child: Row(
                              children: [
                                CountryFlagWidget(
                                  countryCode: server.countryCode,
                                  fallbackEmoji: server.flagEmoji,
                                  width: 28,
                                  height: 20,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            server.country,
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                          if (server.isVip) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.2) : Colors.black,
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                'VIP',
                                                style: TextStyle(
                                                  color: isDark ? const Color(0xFF00F2FE) : Colors.white,
                                                  fontSize: 8,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      Text(
                                        '${server.city} • ${server.continent}',
                                        style: TextStyle(color: textSecondary, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.network_check_rounded,
                                      size: 14,
                                      color: server.ping < 80
                                          ? Colors.greenAccent
                                          : (server.ping < 160 ? Colors.amberAccent : Colors.orangeAccent),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${server.ping} ms',
                                      style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
          },
        );
      },
    );
  }
}
