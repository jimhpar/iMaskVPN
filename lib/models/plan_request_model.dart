import 'package:cloud_firestore/cloud_firestore.dart';

class PlanRequestModel {
  final String id;
  final String uid;
  final String userName;
  final String userEmail;
  final String currentPlan;
  final String requestedPlan;
  final int priceBDT;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime requestedAt;
  final DateTime? processedAt;

  PlanRequestModel({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userEmail,
    required this.currentPlan,
    required this.requestedPlan,
    required this.priceBDT,
    this.status = 'pending',
    required this.requestedAt,
    this.processedAt,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  factory PlanRequestModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PlanRequestModel(
      id: doc.id,
      uid: data['uid'] as String? ?? '',
      userName: data['userName'] as String? ?? 'iMask Member',
      userEmail: data['userEmail'] as String? ?? '',
      currentPlan: data['currentPlan'] as String? ?? 'free',
      requestedPlan: data['requestedPlan'] as String? ?? 'pro',
      priceBDT: (data['priceBDT'] as num? ?? 99).toInt(),
      status: data['status'] as String? ?? 'pending',
      requestedAt: data['requestedAt'] is Timestamp
          ? (data['requestedAt'] as Timestamp).toDate()
          : DateTime.now(),
      processedAt: data['processedAt'] is Timestamp
          ? (data['processedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'userName': userName,
      'userEmail': userEmail,
      'currentPlan': currentPlan,
      'requestedPlan': requestedPlan,
      'priceBDT': priceBDT,
      'status': status,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'processedAt': processedAt != null ? Timestamp.fromDate(processedAt!) : null,
    };
  }
}

