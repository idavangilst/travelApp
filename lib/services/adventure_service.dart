import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/adventure.dart';

class AdventureService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================
  // CREATE ADVENTURE
  // ==========================================

  Future<Adventure> createAdventure({
    required String adventureName,
    required String destination,
    required DateTime startDate,
    required DateTime endDate,
    String? coverImageUrl,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in.',
      );
    }

    final String inviteCode =
        _generateInviteCode();

    final DocumentReference<
        Map<String, dynamic>> adventureRef =
        await _firestore
            .collection('adventures')
            .add({
      'name': adventureName,
      'destination': destination,
      'startDate':
          Timestamp.fromDate(startDate),
      'endDate':
          Timestamp.fromDate(endDate),
      'ownerId': user.uid,
      'memberIds': [user.uid],
      'inviteCode': inviteCode,

      // Cover image
      'coverImageUrl': coverImageUrl,

      'createdAt':
          FieldValue.serverTimestamp(),
    });

    final DocumentSnapshot<
        Map<String, dynamic>> snapshot =
        await adventureRef.get();

    return Adventure.fromFirestore(snapshot);
  }

  // ==========================================
  // JOIN ADVENTURE
  // ==========================================

  Future<Adventure> joinAdventure({
    required String inviteCode,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in.',
      );
    }

    // Find adventure by invite code
    final QuerySnapshot<
        Map<String, dynamic>> querySnapshot =
        await _firestore
            .collection('adventures')
            .where(
              'inviteCode',
              isEqualTo: inviteCode,
            )
            .limit(1)
            .get();

    // No adventure found
    if (querySnapshot.docs.isEmpty) {
      throw Exception(
        'Adventure not found.',
      );
    }

    final DocumentSnapshot<
        Map<String, dynamic>> document =
        querySnapshot.docs.first;

    final Adventure adventure =
        Adventure.fromFirestore(document);

    // Check if user is already a member
    if (adventure.memberIds.contains(user.uid)) {
      throw Exception(
        'You are already a member.',
      );
    }

    // Add user to member list
    await document.reference.update({
      'memberIds': FieldValue.arrayUnion(
        [user.uid],
      ),
    });

    // Get updated adventure
    final DocumentSnapshot<
        Map<String, dynamic>> updatedDocument =
        await document.reference.get();

    return Adventure.fromFirestore(
      updatedDocument,
    );
  }

  // ==========================================
  // INVITE CODE
  // ==========================================

  String _generateInviteCode() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

    final int random =
        DateTime.now().millisecondsSinceEpoch;

    return 'EVR-'
        '${chars[random % chars.length]}'
        '${chars[(random ~/ 3) % chars.length]}'
        '${chars[(random ~/ 7) % chars.length]}'
        '${chars[(random ~/ 11) % chars.length]}';
  }
}