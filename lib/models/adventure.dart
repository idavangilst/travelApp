import 'package:cloud_firestore/cloud_firestore.dart';

class Adventure {
  final String id;
  final String name;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String ownerId;
  final List<String> memberIds;
  final String inviteCode;
  final DateTime? createdAt;

  const Adventure({
    required this.id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.ownerId,
    required this.memberIds,
    required this.inviteCode,
    this.createdAt,
  });

  factory Adventure.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw Exception('Adventure data is missing.');
    }

    return Adventure(
      id: document.id,
      name: data['name'] as String,
      destination: data['destination'] as String,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      ownerId: data['ownerId'] as String,
      memberIds: List<String>.from(data['memberIds'] ?? []),
      inviteCode: data['inviteCode'] as String,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'ownerId': ownerId,
      'memberIds': memberIds,
      'inviteCode': inviteCode,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}
