import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<String> getUserName(String userId) async {
    try {
      final document = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!document.exists) {
        return 'Traveler';
      }

      final data = document.data();

      if (data == null) {
        return 'Traveler';
      }

      final name = data['name']?.toString().trim();

      if (name == null || name.isEmpty) {
        return 'Traveler';
      }

      return name;
    } catch (_) {
      return 'Traveler';
    }
  }

  Future<Map<String, String>> getUserNames(
    List<String> userIds,
  ) async {
    final Map<String, String> names = {};

    for (final userId in userIds) {
      names[userId] = await getUserName(userId);
    }

    return names;
  }
}