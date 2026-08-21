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
  final String? coverImageUrl;
  final String defaultCurrency;
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
    this.coverImageUrl,
    required this.defaultCurrency,
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
      name: data['name']?.toString() ?? '',
      destination: data['destination']?.toString() ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      ownerId: data['ownerId']?.toString() ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      inviteCode: data['inviteCode']?.toString() ?? '',
      coverImageUrl: data['coverImageUrl']?.toString(),
      defaultCurrency:
          data['defaultCurrency']?.toString() ?? 'DKK',
      createdAt: data['createdAt'] is Timestamp
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
      'coverImageUrl': coverImageUrl,
      'defaultCurrency': defaultCurrency,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}