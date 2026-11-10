class VpnServer {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String flagEmoji;
  final String continent;
  final String city;
  final String ip;
  final int port;
  final String protocol;
  int ping; // in ms
  final bool isVip;
  final String? configData;

  VpnServer({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.flagEmoji,
    required this.continent,
    required this.city,
    required this.ip,
    required this.port,
    this.protocol = 'WireGuard',
    this.ping = 25,
    this.isVip = false,
    this.configData,
  });

  factory VpnServer.fromMap(Map<String, dynamic> map) {
    return VpnServer(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      country: map['country'] ?? '',
      countryCode: map['countryCode'] ?? '',
      flagEmoji: map['flagEmoji'] ?? '🌐',
      continent: map['continent'] ?? 'Global',
      city: map['city'] ?? '',
      ip: map['ip'] ?? '',
      port: map['port'] ?? 51820,
      protocol: map['protocol'] ?? 'WireGuard',
      ping: map['ping'] ?? 50,
      isVip: map['isVip'] ?? false,
      configData: map['configData'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'countryCode': countryCode,
      'flagEmoji': flagEmoji,
      'continent': continent,
      'city': city,
      'ip': ip,
      'port': port,
      'protocol': protocol,
      'ping': ping,
      'isVip': isVip,
      'configData': configData,
    };
  }
}
