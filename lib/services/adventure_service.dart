import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/adventure.dart';

class AdventureService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  Future<Adventure> createAdventure({
    required String adventureName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception('No user is currently logged in.');
    }

    // Generate a unique invite code
    final String inviteCode = _generateInviteCode();

    // Create adventure in Firestore
    final DocumentReference<Map<String, dynamic>> adventureRef =
        await _firestore.collection('adventures').add({
      'name': adventureName,
      'destination': destination,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'ownerId': user.uid,
      'memberIds': [user.uid],
      'inviteCode': inviteCode,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Get the newly created adventure
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await adventureRef.get();

    return Adventure.fromFirestore(snapshot);
  }

  String _generateInviteCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final int random = DateTime.now().millisecondsSinceEpoch;

    return 'EVR-${chars[random % chars.length]}'
        '${chars[(random ~/ 3) % chars.length]}'
        '${chars[(random ~/ 7) % chars.length]}'
        '${chars[(random ~/ 11) % chars.length]}';
  }
}
