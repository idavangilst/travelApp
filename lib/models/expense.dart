import 'package:cloud_firestore/cloud_firestore.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final String paidBy;
  final List<String> splitBetween;
  final String createdBy;
  final DateTime? createdAt;

  const Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitBetween,
    required this.createdBy,
    this.createdAt,
  });

  factory Expense.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      throw Exception('Expense data is missing.');
    }

    final createdAtData = data['createdAt'];

    return Expense(
      id: document.id,
      title: data['title']?.toString() ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      currency: data['currency']?.toString().toUpperCase() ?? 'DKK',
      paidBy: data['paidBy']?.toString() ?? '',
      splitBetween: List<String>.from(
        data['splitBetween'] ?? [],
      ),
      createdBy: data['createdBy']?.toString() ?? '',
      createdAt: createdAtData is Timestamp
          ? createdAtData.toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'currency': currency.toUpperCase(),
      'paidBy': paidBy,
      'splitBetween': splitBetween,
      'createdBy': createdBy,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
    };
  }
}