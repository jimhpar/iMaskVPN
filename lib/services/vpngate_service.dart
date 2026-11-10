import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/vpn_server.dart';

class VpnGateService {
  static const String apiUrl = 'http://www.vpngate.net/api/iphone/';

  /// Fetches real live servers from VPN Gate and returns a list of VpnServer objects
  static Future<List<VpnServer>> fetchLiveServers({Duration timeout = const Duration(seconds: 8)}) async {
    final List<VpnServer> servers = [];
    final client = HttpClient();
    client.connectionTimeout = timeout;

    try {
      final request = await client.getUrl(Uri.parse(apiUrl));
      request.headers.set('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)');
      final response = await request.close().timeout(timeout);

      if (response.statusCode != 200) {
        debugPrint('[VpnGateService] API returned status: ${response.statusCode}');
        return [];
      }

      final content = await response.transform(utf8.decoder).join();
      final lines = LineSplitter.split(content).where((l) => l.isNotEmpty && !l.startsWith('*')).toList();

      if (lines.length < 2) return [];

      final header = lines[0].split(',');
      final Map<String, int> headerIndices = {};
      for (int i = 0; i < header.length; i++) {
        headerIndices[header[i].replaceAll('#', '').trim()] = i;
      }

      final ipIdx = headerIndices['IP'] ?? 1;
      final scoreIdx = headerIndices['Score'] ?? 2;
      final pingIdx = headerIndices['Ping'] ?? 3;
      final countryLongIdx = headerIndices['CountryLong'] ?? 5;
      final countryShortIdx = headerIndices['CountryShort'] ?? 6;
      final ovpnIdx = headerIndices['OpenVPN_ConfigData_Base64'] ?? 14;

      // Group candidate servers by country code, pick best by score/ping
      final Map<String, _VpnGateEntry> bestPerCountry = {};

      for (int i = 1; i < lines.length; i++) {
        final cols = lines[i].split(',');
        if (cols.length <= ovpnIdx) continue;

        final ip = cols[ipIdx].trim();
        final score = int.tryParse(cols[scoreIdx].trim()) ?? 0;
        final ping = int.tryParse(cols[pingIdx].trim()) ?? 99;
        final countryLong = cols[countryLongIdx].trim();
        final countryShort = cols[countryShortIdx].trim().toUpperCase();
        final ovpnB64 = cols[ovpnIdx].trim();

        if (ip.isEmpty || countryShort.isEmpty || ovpnB64.isEmpty) continue;

        final entry = _VpnGateEntry(
          ip: ip,
          score: score,
          ping: ping,
          countryLong: countryLong,
          countryShort: countryShort,
          ovpnBase64: ovpnB64,
        );

        if (!bestPerCountry.containsKey(countryShort) || score > bestPerCountry[countryShort]!.score) {
          bestPerCountry[countryShort] = entry;
        }
      }

      // Convert best entries to VpnServer models
      for (final entry in bestPerCountry.values) {
        String decodedOvpn = '';
        try {
          decodedOvpn = utf8.decode(base64.decode(entry.ovpnBase64));
        } catch (_) {}

        if (decodedOvpn.isEmpty) continue;

        final continent = _getContinentByCountryCode(entry.countryShort);
        final flagEmoji = _countryCodeToEmoji(entry.countryShort);

        servers.add(
          VpnServer(
            id: 'vpngate-${entry.countryShort.toLowerCase()}',
            name: '${entry.countryLong} Relay',
            country: entry.countryLong,
            countryCode: entry.countryShort,
            flagEmoji: flagEmoji,
            continent: continent,
            city: 'Public Relay',
            ip: entry.ip,
            port: 443,
            protocol: 'OpenVPN',
            ping: entry.ping > 0 ? entry.ping : 45,
            isVip: false,
            configData: decodedOvpn,
          ),
        );
      }
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
      case 'AU':
      case 'NZ':
        return 'Asia & Pacific';
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
  final String ip;
  final int score;
  final int ping;
  final String countryLong;
  final String countryShort;
  final String ovpnBase64;

  _VpnGateEntry({
    required this.ip,
    required this.score,
    required this.ping,
    required this.countryLong,
    required this.countryShort,
    required this.ovpnBase64,
  });
}

