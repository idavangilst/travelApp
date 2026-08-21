import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/expense.dart';

class ExpenseService {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ==========================================
  // ADD EXPENSE
  // ==========================================

  Future<Expense> addExpense({
    required String adventureId,
    required String title,
    required double amount,
    required String currency,
    required String paidBy,
    required List<String> splitBetween,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in.',
      );
    }

    if (title.trim().isEmpty) {
      throw Exception(
        'Please enter an expense title.',
      );
    }

    if (amount <= 0) {
      throw Exception(
        'Amount must be greater than zero.',
      );
    }

    if (splitBetween.isEmpty) {
      throw Exception(
        'Please select at least one traveler.',
      );
    }

    final DocumentReference<Map<String, dynamic>>
        expenseRef = await _firestore
            .collection('adventures')
            .doc(adventureId)
            .collection('expenses')
            .add({
      'title': title.trim(),
      'amount': amount,
      'currency': currency.toUpperCase(),
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'createdBy': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });

    final snapshot = await expenseRef.get();

    return Expense.fromFirestore(snapshot);
  }

  // ==========================================
  // GET EXPENSES
  // ==========================================

  Stream<List<Expense>> getExpenses(
    String adventureId,
  ) {
    return _firestore
        .collection('adventures')
        .doc(adventureId)
        .collection('expenses')
        .snapshots()
        .map((snapshot) {
      final expenses = snapshot.docs
          .map(
            (document) =>
                Expense.fromFirestore(document),
          )
          .toList();

      expenses.sort((a, b) {
        final aDate = a.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        final bDate = b.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);

        return bDate.compareTo(aDate);
      });

      return expenses;
    });
  }

  // ==========================================
  // DELETE EXPENSE
  // ==========================================

  Future<void> deleteExpense({
    required String adventureId,
    required String expenseId,
  }) async {
    await _firestore
        .collection('adventures')
        .doc(adventureId)
        .collection('expenses')
        .doc(expenseId)
        .delete();
  }

  // ==========================================
  // MARK SETTLEMENT AS PAID
  // ==========================================

  Future<void> markSettlementAsPaid({
    required String adventureId,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required String currency,
  }) async {
    final User? user = _auth.currentUser;

    if (user == null) {
      throw Exception(
        'No user is currently logged in.',
      );
    }

    await _firestore
        .collection('adventures')
        .doc(adventureId)
        .collection('settlements')
        .add({
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'status': 'paid',
      'createdBy': user.uid,
      'paidAt': FieldValue.serverTimestamp(),
    });
  }

  // ==========================================
  // GET SETTLEMENTS
  // ==========================================

  Stream<List<Map<String, dynamic>>> getSettlements(
    String adventureId,
  ) {
    return _firestore
        .collection('adventures')
        .doc(adventureId)
        .collection('settlements')
        .orderBy(
          'paidAt',
          descending: true,
        )
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map(
            (document) => {
              'id': document.id,
              ...document.data(),
            },
          )
          .toList();
    });
  }
}