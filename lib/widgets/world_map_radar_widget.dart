import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/vpn_server.dart';
import '../services/vpn_service.dart';
import 'country_flag_widget.dart';

class WorldMapRadarWidget extends StatefulWidget {
  final VpnServer? selectedServer;
  final VpnStatus status;

  const WorldMapRadarWidget({
    super.key,
    required this.selectedServer,
    required this.status,
  });

  @override
  State<WorldMapRadarWidget> createState() => _WorldMapRadarWidgetState();
}

class _WorldMapRadarWidgetState extends State<WorldMapRadarWidget>
    with TickerProviderStateMixin {
  late AnimationController _flightController;
  late AnimationController _pulseController;
  late Animation<double> _flightAnimation;

  // Origin coordinate (Dhaka, Bangladesh on Equirectangular projection: lon 90.4, lat 23.8)
  final Offset _origin = const Offset(0.751, 0.416);
  Offset _destination = const Offset(0.316, 0.454); // Default Puerto Rico

  @override
  void initState() {
    super.initState();
    _flightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _flightAnimation = CurvedAnimation(
      parent: _flightController,
      curve: Curves.easeInOutCubic,
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _updateDestination();
    _flightController.forward();
  }

  @override
  void didUpdateWidget(covariant WorldMapRadarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedServer?.id != widget.selectedServer?.id ||
        oldWidget.status != widget.status) {
      _updateDestination();
      _flightController.reset();
      _flightController.forward();
    }
  }

  void _updateDestination() {
    final country = widget.selectedServer?.country ?? '';
    final continent = widget.selectedServer?.continent ?? '';
    setState(() {
      _destination = _getCoordinates(country, continent);
    });
  }

  Offset _getCoordinates(String country, String continent) {
    final c = country.toLowerCase().trim();
    final cont = continent.toLowerCase().trim();

    // Mathematically aligned to Equirectangular bounds:
    // lon: [-180, 180] -> dx = (lon + 180) / 360
    // lat: [-58, 82]   -> dy = (82 - lat) / 140

    // Asia & Pacific
    if (c.contains('bangladesh')) return const Offset(0.751, 0.416);
    if (c.contains('india')) return const Offset(0.719, 0.438);
    if (c.contains('malaysia')) return const Offset(0.782, 0.563);
    if (c.contains('singapore')) return const Offset(0.788, 0.576);
    if (c.contains('japan')) return const Offset(0.888, 0.331);
    if (c.contains('korea')) return const Offset(0.853, 0.318);
    if (c.contains('hong kong')) return const Offset(0.817, 0.426);
    if (c.contains('taiwan')) return const Offset(0.837, 0.417);
    if (c.contains('thailand')) return const Offset(0.779, 0.488);
    if (c.contains('vietnam')) return const Offset(0.800, 0.471);
    if (c.contains('indonesia')) return const Offset(0.797, 0.630);
    if (c.contains('philippines')) return const Offset(0.836, 0.494);
    if (c.contains('australia')) return const Offset(0.920, 0.828);
    if (c.contains('new zealand')) return const Offset(0.986, 0.878);
    if (c.contains('pakistan')) return const Offset(0.693, 0.370);
    if (c.contains('sri lanka')) return const Offset(0.724, 0.536);
    if (c.contains('nepal')) return const Offset(0.734, 0.384);

    // Americas
    if (c.contains('puerto')) return const Offset(0.316, 0.454);
    if (c.contains('united states') || c.contains('usa')) return const Offset(0.240, 0.315);
    if (c.contains('canada')) return const Offset(0.260, 0.220);
    if (c.contains('mexico')) return const Offset(0.215, 0.417);
    if (c.contains('brazil')) return const Offset(0.371, 0.754);
    if (c.contains('argentina')) return const Offset(0.338, 0.833);
    if (c.contains('colombia')) return const Offset(0.300, 0.557);
    if (c.contains('chile')) return const Offset(0.304, 0.812);
    if (c.contains('peru')) return const Offset(0.291, 0.654);

    // Europe
    if (c.contains('united kingdom') || c.contains('uk') || c.contains('britain')) return const Offset(0.499, 0.218);
    if (c.contains('germany')) return const Offset(0.524, 0.228);
    if (c.contains('france')) return const Offset(0.506, 0.237);
    if (c.contains('netherlands')) return const Offset(0.514, 0.211);
    if (c.contains('switzerland')) return const Offset(0.524, 0.247);
    if (c.contains('spain')) return const Offset(0.490, 0.297);
    if (c.contains('italy')) return const Offset(0.535, 0.286);
    if (c.contains('sweden')) return const Offset(0.550, 0.162);
    if (c.contains('norway')) return const Offset(0.530, 0.158);
    if (c.contains('finland')) return const Offset(0.569, 0.156);
    if (c.contains('poland')) return const Offset(0.558, 0.213);
    if (c.contains('turkey')) return const Offset(0.581, 0.293);
    if (c.contains('ireland')) return const Offset(0.483, 0.207);
    if (c.contains('austria')) return const Offset(0.545, 0.246);
    if (c.contains('belgium')) return const Offset(0.512, 0.223);
    if (c.contains('denmark')) return const Offset(0.528, 0.187);
    if (c.contains('portugal')) return const Offset(0.476, 0.309);
    if (c.contains('ukraine')) return const Offset(0.587, 0.233);
    if (c.contains('russia')) return const Offset(0.700, 0.190);

    // Middle East & Africa
    if (c.contains('emirates') || c.contains('uae') || c.contains('dubai')) return const Offset(0.654, 0.406);
    if (c.contains('saudi')) return const Offset(0.630, 0.409);
    if (c.contains('qatar')) return const Offset(0.643, 0.405);
    if (c.contains('israel')) return const Offset(0.597, 0.359);
    if (c.contains('egypt')) return const Offset(0.587, 0.371);
    if (c.contains('south africa')) return const Offset(0.578, 0.773);
    if (c.contains('nigeria')) return const Offset(0.521, 0.521);
    if (c.contains('kenya')) return const Offset(0.602, 0.587);

    // Fallbacks by continent
    if (cont.contains('europe')) return const Offset(0.520, 0.230);
    if (cont.contains('asia')) return const Offset(0.760, 0.400);
    if (cont.contains('africa')) return const Offset(0.560, 0.580);
    if (cont.contains('america') && cont.contains('south')) return const Offset(0.330, 0.720);
    if (cont.contains('america')) return const Offset(0.240, 0.320);
    if (cont.contains('oceania')) return const Offset(0.920, 0.820);

    return const Offset(0.500, 0.350);
  }

  @override
  void dispose() {
    _flightController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = widget.status == VpnStatus.connected;
    final isConnecting = widget.status == VpnStatus.connecting;

    final bgColor = isDark ? const Color(0xFF090E1A) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black;
    final textSecondary = isDark ? Colors.white60 : const Color(0xFF64748B);
    final accentColor = isDark ? const Color(0xFF00F2FE) : Colors.black;

    // Tint color for continent silhouettes
    final mapColor = isDark
        ? const Color(0xFF1C2B47).withValues(alpha: 0.85)
        : const Color(0xFF94A3B8).withValues(alpha: 0.45);

    final flag = widget.selectedServer?.flagEmoji ?? '🌐';
    final country = widget.selectedServer?.country ?? 'Global Route';
    final ip = isConnected ? (widget.selectedServer?.ip ?? '129.225.114.149') : '150.228.135.113';

    return Container(
      height: 205,
      width: double.infinity,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        // Subtle border instead of harsh black border
        border: Border.all(
          color: isDark ? const Color(0xFF1E293B) : Colors.black.withValues(alpha: 0.05),
          width: 1.0,
        ),
        // Soft elevated drop shadow
        boxShadow: [
          BoxShadow(
            color: (isConnected && isDark)
                ? const Color(0xFF00F2FE).withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: isDark ? 0.3 : 0.07),
            blurRadius: 18,
            offset: const Offset(0, 5),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Authentic World Map Silhouette
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Image.asset(
                  'assets/map/world_map.png',
                  fit: BoxFit.fill,
                  color: mapColor,
                  colorBlendMode: BlendMode.srcIn,
                  errorBuilder: (context, error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

            // 2. Map Canvas & Flight Path Animation
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([_flightAnimation, _pulseController]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _MapFlightPainter(
                      origin: _origin,
                      destination: _destination,
                      flightProgress: _flightAnimation.value,
                      pulseProgress: _pulseController.value,
                      isDark: isDark,
                      isConnected: isConnected,
                      isConnecting: isConnecting,
                    ),
                  );
                },
              ),
            ),

            // 3. Top HUD Banner
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Location Tag Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF131C30).withValues(alpha: 0.92) : Colors.black,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CountryFlagWidget(
                          countryCode: widget.selectedServer?.countryCode ?? '',
                          fallbackEmoji: flag,
                          width: 22,
                          height: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          country,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Protected IP Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isConnected
                          ? (isDark ? const Color(0xFF00F2FE).withValues(alpha: 0.2) : Colors.black)
                          : (isDark ? Colors.white10 : Colors.white),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isConnected
                            ? (isDark ? const Color(0xFF00F2FE) : Colors.black)
                            : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.08)),
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isConnected
                                ? const Color(0xFF00E676)
                                : (isConnecting ? Colors.amberAccent : Colors.redAccent),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          ip,
                          style: GoogleFonts.sourceCodePro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isConnected
                                ? (isDark ? const Color(0xFF00F2FE) : Colors.white)
                                : (isDark ? Colors.white70 : Colors.black87),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4. Bottom Route Telemetry
            Positioned(
              bottom: 10,
              left: 14,
              right: 14,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (isConnected)
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF00E676),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Encrypted Tunnel Active • $country',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        Icon(Icons.flight_takeoff_rounded, size: 14, color: accentColor),
                        const SizedBox(width: 5),
                        Text(
                          'Dhaka, BD  ➔  $country',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                  Text(
                    isConnected ? '256-bit WireGuard' : 'Ready to Connect',
                    style: TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom Painter for Curved Flight Arc & Plane Particle
class _MapFlightPainter extends CustomPainter {
  final Offset origin;
  final Offset destination;
  final double flightProgress;
  final double pulseProgress;
  final bool isDark;
  final bool isConnected;
  final bool isConnecting;

  _MapFlightPainter({
    required this.origin,
    required this.destination,
    required this.flightProgress,
    required this.pulseProgress,
    required this.isDark,
    required this.isConnected,
    required this.isConnecting,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Subtle latitude and longitude radar grid lines
    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.black).withValues(alpha: isDark ? 0.04 : 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = w * 0.1; x < w; x += w * 0.15) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), gridPaint);
    }
    for (double y = h * 0.2; y < h; y += h * 0.25) {
      canvas.drawLine(Offset(0, y), Offset(w, y), gridPaint);
    }

    final p1 = Offset(origin.dx * w, origin.dy * h);
    final p2 = Offset(destination.dx * w, destination.dy * h);

    // WHEN NOT CONNECTED: Draw flight path arc, trail, origin beacon and flying plane
    // WHEN CONNECTED: Remove source track mark; only destination flashes green!
    if (!isConnected) {
      // Parabolic control point for flight arc (curves upwards)
      final midX = (p1.dx + p2.dx) / 2;
      final curveDepth = min(p1.dy, p2.dy) - (h * 0.28);
      final controlPoint = Offset(midX, curveDepth.clamp(h * 0.08, h * 0.85));

      // Guide curve
      final fullPath = Path();
      fullPath.moveTo(p1.dx, p1.dy);
      fullPath.quadraticBezierTo(controlPoint.dx, controlPoint.dy, p2.dx, p2.dy);

      final guidePaint = Paint()
        ..color = (isDark ? const Color(0xFF00F2FE) : Colors.black).withValues(alpha: isDark ? 0.18 : 0.20)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawPath(fullPath, guidePaint);

      // Draw animated flight path trail
      try {
        final metrics = fullPath.computeMetrics().toList();
        if (metrics.isNotEmpty) {
          final metric = metrics.first;
          final animatedDistance = metric.length * flightProgress;
          final animatedPath = metric.extractPath(0, animatedDistance);

          final trailPaint = Paint()
            ..color = isDark ? const Color(0xFF00F2FE) : Colors.black
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.4;

          canvas.drawPath(animatedPath, trailPaint);
        }
      } catch (_) {}

      // Current flight position along quadratic curve
      final t = flightProgress;
      final currentX = pow(1 - t, 2) * p1.dx + 2 * (1 - t) * t * controlPoint.dx + pow(t, 2) * p2.dx;
      final currentY = pow(1 - t, 2) * p1.dy + 2 * (1 - t) * t * controlPoint.dy + pow(t, 2) * p2.dy;
      final currentPos = Offset(currentX.toDouble(), currentY.toDouble());

      // Origin Beacon (Dhaka, Bangladesh)
      final originPaint = Paint()..color = isDark ? Colors.white : Colors.black;
      canvas.drawCircle(p1, 5.0, originPaint);
      canvas.drawCircle(p1, 2.2, Paint()..color = isDark ? const Color(0xFF00F2FE) : Colors.white);

      // Flying Airplane Particle Oriented Towards Trajectory
      final dxDt = 2 * (1 - t) * (controlPoint.dx - p1.dx) + 2 * t * (p2.dx - controlPoint.dx);
      final dyDt = 2 * (1 - t) * (controlPoint.dy - p1.dy) + 2 * t * (p2.dy - controlPoint.dy);
      final headingAngle = atan2(dyDt, dxDt);

      canvas.save();
      canvas.translate(currentPos.dx, currentPos.dy);
      canvas.rotate(headingAngle);

      final jetGlow = Paint()
        ..color = (isDark ? const Color(0xFF00F2FE) : Colors.black).withValues(alpha: 0.5)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
      canvas.drawCircle(Offset.zero, 6.0, jetGlow);

      final planePath = Path();
      planePath.moveTo(7.0, 0);          // Nose
      planePath.lineTo(-5.0, -5.0);      // Left wing tip
      planePath.lineTo(-2.5, 0);         // Body indent
      planePath.lineTo(-5.0, 5.0);       // Right wing tip
      planePath.close();

      final planePaint = Paint()
        ..color = isDark ? const Color(0xFF00F2FE) : Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawPath(planePath, planePaint);

      canvas.restore();
    }

    // Destination Node with Pulsing Green Radar Rings when connected!
    final pulseColor = isConnected
        ? const Color(0xFF00E676) // Vivid Green
        : (isConnecting ? Colors.amberAccent : (isDark ? const Color(0xFF00F2FE) : Colors.black));

    // Outer pulsing ring
    final pulseRadius = 5.0 + (pulseProgress * (isConnected ? 18.0 : 15.0));
    final pulsePaint = Paint()
      ..color = pulseColor.withValues(alpha: (1.0 - pulseProgress).clamp(0.0, 1.0) * (isConnected ? 0.9 : 0.6))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isConnected ? 2.5 : 2.0;

    canvas.drawCircle(p2, pulseRadius, pulsePaint);

    // Secondary inner pulse (for flashing radar ripple effect)
    final secondaryProgress = (pulseProgress + 0.5) % 1.0;
    final pulseRadius2 = 4.0 + (secondaryProgress * (isConnected ? 12.0 : 11.0));
    final pulsePaint2 = Paint()
      ..color = pulseColor.withValues(alpha: (1.0 - secondaryProgress).clamp(0.0, 1.0) * (isConnected ? 0.8 : 0.5))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;
    canvas.drawCircle(p2, pulseRadius2, pulsePaint2);

    // Glow behind the green dot when connected
    if (isConnected) {
      final glowPaint = Paint()
        ..color = pulseColor.withValues(alpha: 0.65)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(p2, 8.0, glowPaint);
    }

    // Center target pin (Vivid Green when connected)
    canvas.drawCircle(p2, isConnected ? 7.0 : 6.0, Paint()..color = pulseColor);
    canvas.drawCircle(p2, isConnected ? 3.0 : 2.5, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _MapFlightPainter oldDelegate) => true;
}
