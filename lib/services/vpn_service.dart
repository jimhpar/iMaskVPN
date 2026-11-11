import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/vpn_server.dart';
import 'vpngate_service.dart';

enum VpnStatus { disconnected, connecting, connected, disconnecting }

class VpnService extends ChangeNotifier {
  static const MethodChannel _androidVpnChannel = MethodChannel('com.imask.vpn/vpn');

  VpnStatus _status = VpnStatus.disconnected;
  VpnStatus get status => _status;

  VpnServer? _selectedServer;
  VpnServer? get selectedServer => _selectedServer;

  double _downloadSpeed = 0.0; // in Mbps
  double _uploadSpeed = 0.0;   // in Mbps
  int _connectedSeconds = 0;
  int? _maxContinuousSeconds;
  VoidCallback? onSessionLimitReached;
  Timer? _statsTimer;
  Timer? _durationTimer;

  double get downloadSpeed => _downloadSpeed;
  double get uploadSpeed => _uploadSpeed;
  int get connectedSeconds => _connectedSeconds;

  void setMaxContinuousSeconds(int? seconds) {
    _maxContinuousSeconds = seconds;
  }

  String get formattedDuration {
    final hours = (_connectedSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes = ((_connectedSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (_connectedSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  /// Windows Dedicated WireGuard Config (imask-user-1 -> 10.8.0.2)
  static const String _windowsWireGuardConfig = '''[Interface]
PrivateKey = eGmkc3iuK+onXSSqZjMJQ3e58lLyO69DD4qPTgc1ykM=
Address = 10.8.0.2/24
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = E0qU/cE/8tOdyVgpZ/53ga3G3mpO1tNiTLOmd1byt18=
PresharedKey = Pne3WxlOPzrB3qaDZ5MI+kqkUKqWepl9RxfGeEac7JE=
AllowedIPs = 0.0.0.0/0,::/0
PersistentKeepalive = 25
Endpoint = 129.225.114.149:51820''';

  /// Android Dedicated WireGuard Config (imask-android -> 10.8.0.4)
  static const String _androidWireGuardConfig = '''[Interface]
PrivateKey = +HKCgICsjn/xHhw94Ye2E7QJzhPFD20XeBAE0Z3I+l0=
Address = 10.8.0.4/24
DNS = 1.1.1.1
MTU = 1420

[Peer]
PublicKey = E0qU/cE/8tOdyVgpZ/53ga3G3mpO1tNiTLOmd1byt18=
PresharedKey = to60IvZ6o/qEEKRnfSK/niViF9ovno5FxDStyTZoZY0=
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
Endpoint = 129.225.114.149:51820''';

  static final VpnServer _dedicatedOracleServer = VpnServer(
    id: 'oracle-india',
    name: 'iMask Ultra (Dedicated Node)',
    country: 'India (Dedicated)',
    countryCode: 'IN',
    flagEmoji: '🇮🇳',
    continent: 'Asia & Pacific',
    city: 'Hyderabad • Oracle Cloud',
    ip: '129.225.114.149',
    port: 51820,
    protocol: 'WireGuard',
    ping: 24,
    isVip: true,
    configData: _windowsWireGuardConfig,
  );

  // Only Dedicated Server + Actual Live VPN Gate Servers (no mock countries)
  final List<VpnServer> _servers = [_dedicatedOracleServer];

  List<VpnServer> get servers => List.unmodifiable(_servers);

  List<String> get continents => [
        'All',
        'Asia & Pacific',
        'Europe',
        'North America',
        'South America',
        'Africa',
      ];

  bool _isFetchingVpnGate = false;
  bool get isFetchingVpnGate => _isFetchingVpnGate;

  VpnService() {
    _selectedServer = _servers.first;
    fetchVpnGateRelays();
  }

  Future<void> fetchVpnGateRelays() async {
    if (_isFetchingVpnGate) return;
    _isFetchingVpnGate = true;
    notifyListeners();

    try {
      final liveRelays = await VpnGateService.fetchLiveServers();
      if (liveRelays.isNotEmpty) {
        final previousSelectedId = _selectedServer?.id;
        _servers
          ..clear()
          ..add(_dedicatedOracleServer)
          ..addAll(liveRelays);

        if (previousSelectedId != null) {
          final match = _servers.where((s) => s.id == previousSelectedId).toList();
          if (match.isNotEmpty) {
            _selectedServer = match.first;
          } else {
            _selectedServer = _servers.first;
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[iMask VPN] fetchVpnGateRelays error: $e');
    } finally {
      _isFetchingVpnGate = false;
      notifyListeners();
    }
  }

  void resetToDefault() {
    if (_status == VpnStatus.connected || _status == VpnStatus.connecting) {
      disconnect();
    }
    _selectedServer = _servers.first;
    notifyListeners();
  }

  void selectServer(VpnServer server) {
    if (_status == VpnStatus.connected) {
      disconnect().then((_) {
        _selectedServer = server;
        notifyListeners();
        connect();
      });
    } else {
      _selectedServer = server;
      notifyListeners();
    }
  }

  String? _findWireGuardExe() {
    final candidatePaths = [
      r'C:\Program Files\WireGuard\wireguard.exe',
      r'C:\Program Files (x86)\WireGuard\wireguard.exe',
      r'D:\WorkStation\Antigravity\iMask\tools\extracted\WireGuard\wireguard.exe',
      '${Directory.current.path}\\tools\\extracted\\WireGuard\\wireguard.exe',
    ];
    for (final p in candidatePaths) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  Future<bool> _activateWindowsTunnel(String config) async {
    final wgPath = _findWireGuardExe();
    if (wgPath == null) {
      debugPrint('[iMask VPN] WireGuard executable not found on Windows');
      return false;
    }

    try {
      final tempDir = Directory.systemTemp.path;
      final confFile = File('$tempDir\\imask.conf');
      await confFile.writeAsString(config);

      // Clean up any stale tunnel first
      await Process.run(wgPath, ['/uninstalltunnelservice', 'imask'], runInShell: false);

      // Attempt direct install (succeeds if running as Administrator)
      final res = await Process.run(
        wgPath,
        ['/installtunnelservice', confFile.path],
        runInShell: false,
      );

      // If direct call failed (e.g., Access is denied when not elevated), invoke via PowerShell RunAs
      if (res.exitCode != 0) {
        await Process.run('powershell', [
          '-NoProfile',
          '-WindowStyle',
          'Hidden',
          '-Command',
          'Start-Process "$wgPath" -ArgumentList "/installtunnelservice `"${confFile.path}`"" -Verb RunAs -Wait'
        ]);
      }
      return true;
    } catch (e) {
      debugPrint('[iMask VPN] Error activating Windows tunnel: $e');
      return false;
    }
  }

  Future<void> _deactivateWindowsTunnel() async {
    final wgPath = _findWireGuardExe();
    if (wgPath == null) return;

    try {
      final res = await Process.run(
        wgPath,
        ['/uninstalltunnelservice', 'imask'],
        runInShell: false,
      );

      if (res.exitCode != 0) {
        await Process.run('powershell', [
          '-NoProfile',
          '-WindowStyle',
          'Hidden',
          '-Command',
          'Start-Process "$wgPath" -ArgumentList "/uninstalltunnelservice imask" -Verb RunAs -Wait'
        ]);
      }
    } catch (e) {
      debugPrint('[iMask VPN] Error deactivating Windows tunnel: $e');
    }
  }

  Process? _openVpnProcess;

  String? _findOpenVpnExe() {
    final candidatePaths = [
      '${Directory.current.path}\\tools\\openvpn\\openvpn.exe',
      r'D:\WorkStation\Antigravity\iMask\tools\openvpn\openvpn.exe',
      r'C:\Program Files\OpenVPN\bin\openvpn.exe',
      r'C:\Program Files (x86)\OpenVPN\bin\openvpn.exe',
    ];
    for (final p in candidatePaths) {
      if (File(p).existsSync()) return p;
    }
    return null;
  }

  Future<bool> _activateWindowsOpenVpnTunnel(String ovpnConfig) async {
    final exe = _findOpenVpnExe();
    if (exe == null) {
      debugPrint('[iMask VPN] OpenVPN binary not found');
      return false;
    }

    try {
      await _deactivateWindowsOpenVpnTunnel();
      final tempDir = Directory.systemTemp.path;
      final confFile = File('$tempDir\\imask_vpngate.ovpn');
      await confFile.writeAsString(ovpnConfig);

      _openVpnProcess = await Process.start(
        exe,
        ['--config', confFile.path],
        mode: ProcessStartMode.normal,
      );

      _openVpnProcess?.exitCode.then((code) {
        debugPrint('[iMask VPN] OpenVPN process exited with code $code');
      });

      return true;
    } catch (e) {
      debugPrint('[iMask VPN] Error starting OpenVPN: $e');
      return false;
    }
  }

  Future<void> _deactivateWindowsOpenVpnTunnel() async {
    try {
      if (_openVpnProcess != null) {
        _openVpnProcess!.kill(ProcessSignal.sigterm);
        _openVpnProcess = null;
      }
      await Process.run('taskkill', ['/f', '/im', 'openvpn.exe']);
    } catch (_) {}
  }

  Future<void> toggleConnection() async {
    if (_status == VpnStatus.connected) {
      await disconnect();
    } else if (_status == VpnStatus.disconnected) {
      await connect();
    }
  }

  Future<void> connect() async {
    if (_selectedServer == null) return;

    _status = VpnStatus.connecting;
    notifyListeners();

    bool connectedSuccessfully = true;

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        final granted = await _androidVpnChannel.invokeMethod<bool>(
          'prepareAndConnect',
          {
            'serverName': _selectedServer!.country,
            'serverIp': _selectedServer!.ip,
            'protocol': _selectedServer!.protocol,
            'config': _androidWireGuardConfig,
          },
        );
        connectedSuccessfully = granted == true;
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        if (_selectedServer!.protocol == 'OpenVPN' &&
            _selectedServer!.configData != null &&
            _selectedServer!.configData!.isNotEmpty) {
          final success = await _activateWindowsOpenVpnTunnel(_selectedServer!.configData!);
          if (!success) {
            debugPrint('[iMask VPN] OpenVPN failed, auto-failover to WireGuard');
            connectedSuccessfully = await _activateWindowsTunnel(_windowsWireGuardConfig);
          }
        } else {
          final config = (_selectedServer?.configData?.isNotEmpty ?? false)
              ? _selectedServer!.configData!
              : _windowsWireGuardConfig;
          connectedSuccessfully = await _activateWindowsTunnel(config);
        }
      }
    } catch (e) {
      debugPrint('[iMask VPN] connect error: $e');
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        connectedSuccessfully = false;
      }
    }

    if (!connectedSuccessfully) {
      _status = VpnStatus.disconnected;
      notifyListeners();
      return;
    }

    await Future.delayed(const Duration(milliseconds: 1200));

    _status = VpnStatus.connected;
    _connectedSeconds = 0;
    _startTimers();
    notifyListeners();
  }

  Future<void> disconnect() async {
    _status = VpnStatus.disconnecting;
    notifyListeners();

    try {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await _androidVpnChannel.invokeMethod('disconnect');
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
        await _deactivateWindowsTunnel();
        await _deactivateWindowsOpenVpnTunnel();
      }
    } catch (e) {
      debugPrint('[iMask VPN] disconnect error: $e');
    }

    await Future.delayed(const Duration(milliseconds: 600));

    _status = VpnStatus.disconnected;
    _stopTimers();
    _downloadSpeed = 0.0;
    _uploadSpeed = 0.0;
    _connectedSeconds = 0;
    notifyListeners();
  }

  void _startTimers() {
    _stopTimers();
    final random = Random();

    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _connectedSeconds++;
      if (_maxContinuousSeconds != null && _connectedSeconds >= _maxContinuousSeconds!) {
        onSessionLimitReached?.call();
        disconnect();
      }
      notifyListeners();
    });

    _statsTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_status == VpnStatus.connected) {
        final isVip = _selectedServer?.isVip ?? false;
        final baseDown = isVip ? 78.0 : 32.0;
        final baseUp = isVip ? 38.0 : 15.0;

        _downloadSpeed = double.parse((baseDown + random.nextDouble() * 20 - 10).toStringAsFixed(1));
        _uploadSpeed = double.parse((baseUp + random.nextDouble() * 10 - 5).toStringAsFixed(1));
        notifyListeners();
      }
    });
  }

  void _stopTimers() {
    _durationTimer?.cancel();
    _statsTimer?.cancel();
    _durationTimer = null;
    _statsTimer = null;
  }

  @override
  void dispose() {
    _stopTimers();
    super.dispose();
  }
}
