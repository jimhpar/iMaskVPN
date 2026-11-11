import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/vpn_server.dart';

class VpnGateService {
  /// Primary Oracle Cloud cached endpoint (fast, lightweight JSON)
  static const String oracleCacheUrl = 'http://129.225.114.149:51821/vpngate.json';

  /// Fallback direct VPN Gate CSV endpoint
  static const String fallbackApiUrl = 'http://www.vpngate.net/api/iphone/';

  /// Fetches real live servers from Oracle Cloud cache first, falling back to VPN Gate API.
  /// When [forceLiveVerify] is true, also performs a real TCP socket reachability check from the client
  /// so any relay that went offline in the last few seconds is immediately removed.
  static Future<List<VpnServer>> fetchLiveServers({
    Duration timeout = const Duration(seconds: 8),
    bool forceLiveVerify = true,
  }) async {
    List<VpnServer> candidateServers = [];

    // 1. Try fast Oracle Cloud cached JSON first (with cache-busting timestamp)
    try {
      final cachedServers = await _fetchFromOracleCache(timeout: const Duration(seconds: 6));
      if (cachedServers.isNotEmpty) {
        debugPrint('[VpnGateService] Loaded ${cachedServers.length} servers from Oracle Cache');
        candidateServers = cachedServers;
      }
    } catch (e) {
      debugPrint('[VpnGateService] Oracle cache unavailable, falling back to direct VPN Gate: $e');
    }

    // 2. Fallback to direct VPN Gate CSV parsing
    if (candidateServers.isEmpty) {
      candidateServers = await _fetchFromDirectCsv(timeout: timeout);
    }

    if (!forceLiveVerify || kIsWeb || candidateServers.isEmpty) {
      return candidateServers;
    }

    // 3. Perform live client-side TCP reachability check in parallel so inactive servers disappear immediately on Refresh
    final List<VpnServer> activeServers = [];
    final futures = candidateServers.map((server) async {
      final isAlive = await _checkTcpAlive(server.ip, server.port);
      return isAlive ? server : null;
    });

    final results = await Future.wait(futures);
    for (final res in results) {
      if (res != null) activeServers.add(res);
    }

    // Re-number country suffixes (#2, #3...) cleanly per country after removing any dead relays
    final Map<String, int> countryCounts = {};
    final List<VpnServer> cleanedServers = [];
    for (final srv in activeServers) {
      final baseCountry = srv.country.split('#').first.trim();
      final count = (countryCounts[srv.countryCode] ?? 0) + 1;
      countryCounts[srv.countryCode] = count;
      final cleanCountryName = count > 1 ? '$baseCountry #$count' : baseCountry;
      cleanedServers.add(
        VpnServer(
          id: srv.id,
          name: srv.name,
          country: cleanCountryName,
          countryCode: srv.countryCode,
          flagEmoji: srv.flagEmoji,
          continent: srv.continent,
          city: srv.city,
          ip: srv.ip,
          port: srv.port,
          protocol: srv.protocol,
          ping: srv.ping,
          isVip: srv.isVip,
          configData: srv.configData,
        ),
      );
    }

    return cleanedServers;
  }

  static Future<bool> _checkTcpAlive(String ip, int port) async {
    try {
      final socket = await Socket.connect(ip, port, timeout: const Duration(milliseconds: 2200));
      socket.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<List<VpnServer>> _fetchFromOracleCache({required Duration timeout}) async {
    if (kIsWeb) return [];
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final uri = Uri.parse('$oracleCacheUrl?t=${DateTime.now().millisecondsSinceEpoch}');
      final request = await client.getUrl(uri);
      request.headers.set('Cache-Control', 'no-cache, no-store, must-revalidate');
      final response = await request.close().timeout(timeout);
      if (response.statusCode != 200) return [];

      final content = await response.transform(utf8.decoder).join();
      final Map<String, dynamic> decoded = jsonDecode(content) as Map<String, dynamic>;
      final List<dynamic> rawServers = decoded['servers'] as List<dynamic>? ?? [];

      final List<VpnServer> result = [];
      for (final item in rawServers) {
        if (item is! Map<String, dynamic>) continue;
        result.add(
          VpnServer(
            id: item['id']?.toString() ?? 'vpngate',
            name: item['name']?.toString() ?? 'VPN Gate Relay',
            country: item['country']?.toString() ?? 'Unknown',
            countryCode: (item['countryCode']?.toString() ?? 'UN').toUpperCase(),
            flagEmoji: item['flagEmoji']?.toString() ?? '🌐',
            continent: item['continent']?.toString() ?? 'Asia & Pacific',
            city: item['city']?.toString() ?? 'VPN Gate Relay',
            ip: item['ip']?.toString() ?? '',
            port: (item['port'] is int) ? item['port'] as int : int.tryParse('${item['port']}') ?? 443,
            protocol: item['protocol']?.toString() ?? 'OpenVPN',
            ping: (item['ping'] is int) ? item['ping'] as int : int.tryParse('${item['ping']}') ?? 45,
            isVip: item['isVip'] == true,
            configData: item['configData']?.toString(),
          ),
        );
      }
      return result;
    } finally {
      client.close();
    }
  }

  static Future<List<VpnServer>> _fetchFromDirectCsv({required Duration timeout}) async {
    if (kIsWeb) return [];
    final List<VpnServer> servers = [];
    final client = HttpClient()..connectionTimeout = timeout;

    try {
      final request = await client.getUrl(Uri.parse(fallbackApiUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        debugPrint('[VpnGateService] Direct API returned status: ${response.statusCode}');
        return [];
      }

      final content = await response.transform(utf8.decoder).join();
      final lines = LineSplitter.split(content)
          .where((l) => l.isNotEmpty && !l.startsWith('*'))
          .toList();

      if (lines.length < 2) return [];

      final header = lines[0].split(',');
      final Map<String, int> headerIndices = {};
      for (int i = 0; i < header.length; i++) {
        headerIndices[header[i].replaceAll('#', '').trim()] = i;
      }

      final hostIdx = headerIndices['HostName'] ?? 0;
      final ipIdx = headerIndices['IP'] ?? 1;
      final scoreIdx = headerIndices['Score'] ?? 2;
      final pingIdx = headerIndices['Ping'] ?? 3;
      final speedIdx = headerIndices['Speed'] ?? 4;
      final countryLongIdx = headerIndices['CountryLong'] ?? 5;
      final countryShortIdx = headerIndices['CountryShort'] ?? 6;
      final ovpnIdx = headerIndices['OpenVPN_ConfigData_Base64'] ?? 14;

      final List<_VpnGateEntry> entries = [];

      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.length <= ovpnIdx) continue;

        final hostName = cols[hostIdx].trim();
        final ip = cols[ipIdx].trim();
        final score = int.tryParse(cols[scoreIdx].trim()) ?? 0;
        final ping = int.tryParse(cols[pingIdx].trim()) ?? 45;
        final speed = int.tryParse(cols[speedIdx].trim()) ?? 0;
        String countryLong = cols[countryLongIdx].trim();
        final countryShort = cols[countryShortIdx].trim().toUpperCase();
        final ovpnB64 = cols[ovpnIdx].trim();

        if (ip.isEmpty || countryShort.isEmpty || ovpnB64.isEmpty) continue;

        if (countryLong.contains('Korea')) {
          countryLong = 'South Korea';
        } else if (countryLong.contains('Viet Nam')) {
          countryLong = 'Vietnam';
        } else if (countryLong.contains('Russian Federation')) {
          countryLong = 'Russia';
        } else if (countryLong.contains('(')) {
          countryLong = countryLong.split('(').first.trim();
        }

        entries.add(
          _VpnGateEntry(
            hostName: hostName.isNotEmpty ? hostName : 'Public Relay',
            ip: ip,
            score: score,
            ping: ping > 0 ? ping : 45,
            speed: speed,
            countryLong: countryLong,
            countryShort: countryShort,
            ovpnBase64: ovpnB64,
          ),
        );
      }

      entries.sort((a, b) => b.score.compareTo(a.score));

      final Map<String, int> countryCounts = {};
      final Set<String> seenIps = {};

      for (final entry in entries) {
        if (seenIps.contains(entry.ip)) continue;
        seenIps.add(entry.ip);

        final count = (countryCounts[entry.countryShort] ?? 0) + 1;
        if (count > 15) continue;
        countryCounts[entry.countryShort] = count;

        String decodedOvpn = '';
        try {
          decodedOvpn = utf8.decode(base64.decode(entry.ovpnBase64), allowMalformed: true);
        } catch (_) {}

        if (decodedOvpn.isEmpty || !decodedOvpn.contains('client')) continue;

        final continent = _getContinentByCountryCode(entry.countryShort);
        final flagEmoji = _countryCodeToEmoji(entry.countryShort);
        final speedMbps = entry.speed > 0 ? (entry.speed / 1000000).toStringAsFixed(1) : null;
        final displayCountry = count > 1 ? '${entry.countryLong} #$count' : entry.countryLong;

        servers.add(
          VpnServer(
            id: 'vpngate-${entry.countryShort.toLowerCase()}-${entry.ip.replaceAll('.', '-')}',
            name: '${entry.countryLong} (${entry.hostName})',
            country: displayCountry,
            countryCode: entry.countryShort,
            flagEmoji: flagEmoji,
            continent: continent,
            city: speedMbps != null ? '${entry.hostName} • $speedMbps Mbps' : '${entry.hostName} • VPN Gate',
            ip: entry.ip,
            port: 443,
            protocol: 'OpenVPN',
            ping: entry.ping,
            isVip: false,
            configData: decodedOvpn,
          ),
        );
      }

      servers.sort((a, b) {
        final aIsPrimary = !a.country.contains('#');
        final bIsPrimary = !b.country.contains('#');
        if (aIsPrimary != bIsPrimary) return aIsPrimary ? -1 : 1;
        return a.ping.compareTo(b.ping);
      });
    } catch (e) {
      debugPrint('[VpnGateService] Error fetching VPN Gate servers: $e');
    } finally {
      client.close();
    }

    return servers;
  }

  static String _countryCodeToEmoji(String code) {
    if (code.length != 2) return '🌐';
    final int first = code.codeUnitAt(0) - 0x41 + 0x1F1E6;
    final int second = code.codeUnitAt(1) - 0x41 + 0x1F1E6;
    return String.fromCharCode(first) + String.fromCharCode(second);
  }

  static String _getContinentByCountryCode(String code) {
    switch (code) {
      case 'JP':
      case 'KR':
      case 'SG':
      case 'MY':
      case 'TH':
      case 'VN':
      case 'ID':
      case 'HK':
      case 'TW':
      case 'IN':
      case 'BD':
      case 'PK':
      case 'NP':
      case 'PH':
      case 'AU':
      case 'NZ':
        return 'Asia & Pacific';
      case 'US':
      case 'CA':
      case 'MX':
        return 'North America';
      case 'GB':
      case 'DE':
      case 'FR':
      case 'NL':
      case 'RO':
      case 'RU':
      case 'UA':
      case 'HR':
      case 'IT':
      case 'ES':
      case 'CH':
      case 'SE':
      case 'NO':
        return 'Europe';
      case 'BR':
      case 'AR':
      case 'CL':
      case 'CO':
        return 'South America';
      case 'ZA':
      case 'EG':
      case 'NG':
      case 'KE':
        return 'Africa';
      default:
        return 'Asia & Pacific';
    }
  }
}

class _VpnGateEntry {
  final String hostName;
  final String ip;
  final int score;
  final int ping;
  final int speed;
  final String countryLong;
  final String countryShort;
  final String ovpnBase64;

  _VpnGateEntry({
    required this.hostName,
    required this.ip,
    required this.score,
    required this.ping,
    required this.speed,
    required this.countryLong,
    required this.countryShort,
    required this.ovpnBase64,
  });
}
