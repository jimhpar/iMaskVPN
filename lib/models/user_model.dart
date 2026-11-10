import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final String plan; // 'free' | 'pro' | 'ultra'
  final String role; // 'user' | 'admin'
  final int weeklyMinutesUsed;
  final DateTime? createdAt;
  final DateTime? lastLogin;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.plan = 'free',
    this.role = 'user',
    this.weeklyMinutesUsed = 0,
    this.createdAt,
    this.lastLogin,
  });

  bool get isAdmin =>
      role.toLowerCase() == 'admin' ||
      role.toLowerCase() == 'superadmin' ||
      email.toLowerCase() == 'su@imask.com' ||
      email.toLowerCase().contains('admin') ||
      email.toLowerCase() == 'jimhpar@gmail.com';

  bool get isSuperAdmin =>
      role.toLowerCase() == 'superadmin' ||
      email.toLowerCase() == 'su@imask.com';

  String get planBadgeLetter {
    final p = plan.toLowerCase();
    if (p == 'ultra') return 'U';
    if (p == 'pro') return 'P';
    return '';
  }

  String get planTitle {
    final p = plan.toLowerCase();
    if (p == 'ultra') return 'Ultra';
    if (p == 'pro') return 'Pro';
    return 'Free';
  }

  int get planPriceBDT {
    final p = plan.toLowerCase();
    if (p == 'ultra') return 499;
    if (p == 'pro') return 99;
    return 0;
  }

  // Session limits in minutes
  int get maxContinuousMinutes {
    final p = plan.toLowerCase();
    if (p == 'ultra') return 999999;
    if (p == 'pro') return 180; // 3 hours
    return 60; // 1 hour for free
  }

  // Weekly limits in minutes
  int get maxWeeklyMinutes {
    final p = plan.toLowerCase();
    if (p == 'ultra') return 999999;
    if (p == 'pro') return 900; // 15 hours
    return 300; // 5 hours for free
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      uid: id,
      email: data['email'] as String? ?? '',
      displayName: data['displayName'] as String? ?? 'iMask Member',
      plan: (data['plan'] as String? ?? 'free').toLowerCase(),
      role: (data['role'] as String? ?? 'user').toLowerCase(),
      weeklyMinutesUsed: (data['weeklyMinutesUsed'] as num? ?? 0).toInt(),
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastLogin: data['lastLogin'] is Timestamp
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'plan': plan,
      'role': role,
      'weeklyMinutesUsed': weeklyMinutesUsed,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastLogin': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? plan,
    String? role,
    int? weeklyMinutesUsed,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      plan: plan ?? this.plan,
      role: role ?? this.role,
      weeklyMinutesUsed: weeklyMinutesUsed ?? this.weeklyMinutesUsed,
      createdAt: createdAt,
      lastLogin: lastLogin,
    );
  }
}

