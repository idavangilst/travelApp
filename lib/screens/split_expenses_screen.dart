import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../services/currency_service.dart';

class SplitExpensesScreen extends StatefulWidget {
  final String adventureId;
  final String adventureName;

  const SplitExpensesScreen({
    super.key,
    required this.adventureId,
    required this.adventureName,
  });

  @override
  State<SplitExpensesScreen> createState() => _SplitExpensesScreenState();
}

class _SplitExpensesScreenState extends State<SplitExpensesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CurrencyService _currencyService = CurrencyService();

  bool _loading = true;
  bool _calculatingBalances = false;
  String? _error;

  String selectedCurrency = 'DKK';

  List<_Traveler> _travelers = [];
  List<_Expense> _expenses = [];
  List<_Settlement> _settlements = [];
  Map<String, double> _balances = {};

  static const List<String> _currencies = [
    'DKK',
    'EUR',
    'USD',
    'GBP',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _loading = true;
          _error = null;
        });
      }

      final adventureDoc = await _firestore
          .collection('adventures')
          .doc(widget.adventureId)
          .get();

      if (!adventureDoc.exists) {
        throw Exception('Adventure not found.');
      }

      final adventureData = adventureDoc.data();

      if (adventureData == null) {
        throw Exception('Adventure data is missing.');
      }

      final memberIds =
          List<String>.from(adventureData['memberIds'] ?? []);

      // ----------------------------------------------------------
      // USERS
      // ----------------------------------------------------------

      final travelers = <_Traveler>[];

      for (final userId in memberIds) {
        final userDoc =
            await _firestore.collection('users').doc(userId).get();

        final userData = userDoc.data();

        travelers.add(
          _Traveler(
            id: userId,
            name: userData?['name']?.toString() ?? 'Traveler',
          ),
        );
      }

      // ----------------------------------------------------------
      // EXPENSES
      // ----------------------------------------------------------

      final expenseSnapshot = await _firestore
          .collection('adventures')
          .doc(widget.adventureId)
          .collection('expenses')
          .get();

      final expenses = expenseSnapshot.docs.map((doc) {
        final data = doc.data();

        return _Expense(
          id: doc.id,
          title: data['title']?.toString() ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          currency: data['currency']?.toString() ?? 'DKK',
          paidBy: data['paidBy']?.toString() ?? '',
          splitBetween:
              List<String>.from(data['splitBetween'] ?? []),
        );
      }).toList();

      // ----------------------------------------------------------
      // SETTLEMENTS
      // ----------------------------------------------------------

      final settlementSnapshot = await _firestore
          .collection('adventures')
          .doc(widget.adventureId)
          .collection('settlements')
          .get();

      final settlements = settlementSnapshot.docs.map((doc) {
        final data = doc.data();

        return _Settlement(
          fromUserId: data['fromUserId']?.toString() ?? '',
          toUserId: data['toUserId']?.toString() ?? '',
          amount: (data['amount'] as num?)?.toDouble() ?? 0,
          currency: data['currency']?.toString() ?? 'DKK',
          status: data['status']?.toString() ?? '',
        );
      }).toList();

      if (!mounted) return;

      setState(() {
        _travelers = travelers;
        _expenses = expenses;
        _settlements = settlements;
        _loading = false;
      });

      await _updateBalances();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // ============================================================
  // GET NAME
  // ============================================================

  String _getName(String userId) {
    for (final traveler in _travelers) {
      if (traveler.id == userId) {
        return traveler.name;
      }
    }

    return 'Traveler';
  }

  // ============================================================
  // CONVERT AMOUNT
  // ============================================================

  Future<double> _convertAmount(
    double amount,
    String fromCurrency,
  ) async {
    if (fromCurrency == selectedCurrency) {
      return amount;
    }

    return _currencyService.convert(
      amount: amount,
      from: fromCurrency,
      to: selectedCurrency,
    );
  }

  // ============================================================
  // CALCULATE BALANCES
  // ============================================================

  Future<Map<String, double>> _calculateBalancesAsync() async {
    final balances = <String, double>{};

    for (final traveler in _travelers) {
      balances[traveler.id] = 0;
    }

    // ----------------------------------------------------------
    // EXPENSES
    // ----------------------------------------------------------

    for (final expense in _expenses) {
      if (expense.splitBetween.isEmpty) {
        continue;
      }

      final convertedAmount = await _convertAmount(
        expense.amount,
        expense.currency,
      );

      final share =
          convertedAmount / expense.splitBetween.length;

      balances[expense.paidBy] =
          (balances[expense.paidBy] ?? 0) + convertedAmount;

      for (final userId in expense.splitBetween) {
        balances[userId] =
            (balances[userId] ?? 0) - share;
      }
    }

    // ----------------------------------------------------------
    // PAID SETTLEMENTS
    // ----------------------------------------------------------

    for (final settlement in _settlements) {
      if (settlement.status != 'paid') {
        continue;
      }

      final convertedAmount = await _convertAmount(
        settlement.amount,
        settlement.currency,
      );

      balances[settlement.fromUserId] =
          (balances[settlement.fromUserId] ?? 0) +
              convertedAmount;

      balances[settlement.toUserId] =
          (balances[settlement.toUserId] ?? 0) -
              convertedAmount;
    }

    return balances;
  }

  // ============================================================
  // UPDATE BALANCES
  // ============================================================

  Future<void> _updateBalances() async {
    if (!mounted) return;

    setState(() {
      _calculatingBalances = true;
    });

    try {
      final balances = await _calculateBalancesAsync();

      if (!mounted) return;

      setState(() {
        _balances = balances;
        _calculatingBalances = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _calculatingBalances = false;
        _error =
            'Could not calculate currency conversion: $e';
      });
    }
  }

  // ============================================================
  // CALCULATE TRANSFERS
  // ============================================================

  List<_Transfer> _calculateTransfers(
    Map<String, double> balances,
  ) {
    final debtors = <_Balance>[];
    final creditors = <_Balance>[];

    balances.forEach((userId, balance) {
      if (balance < -0.01) {
        debtors.add(
          _Balance(
            userId: userId,
            amount: -balance,
          ),
        );
      } else if (balance > 0.01) {
        creditors.add(
          _Balance(
            userId: userId,
            amount: balance,
          ),
        );
      }
    });

    final transfers = <_Transfer>[];

    int debtorIndex = 0;
    int creditorIndex = 0;

    while (
        debtorIndex < debtors.length &&
        creditorIndex < creditors.length) {
      final debtor = debtors[debtorIndex];
      final creditor = creditors[creditorIndex];

      final amount = debtor.amount < creditor.amount
          ? debtor.amount
          : creditor.amount;

      transfers.add(
        _Transfer(
          fromUserId: debtor.userId,
          toUserId: creditor.userId,
          amount: amount,
        ),
      );

      debtor.amount -= amount;
      creditor.amount -= amount;

      if (debtor.amount < 0.01) {
        debtorIndex++;
      }

      if (creditor.amount < 0.01) {
        creditorIndex++;
      }
    }

    return transfers;
  }

  // ============================================================
  // ADD EXPENSE
  // ============================================================

  Future<void> _showAddExpenseSheet() async {
    final titleController = TextEditingController();
    final amountController = TextEditingController();

    String expenseCurrency = selectedCurrency;
    String? paidBy;

    final selectedTravelers = <String>{
      ..._travelers.map((traveler) => traveler.id),
    };

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _expenseSheet(
              context: context,
              sheetContext: sheetContext,
              title: 'Add expense',
              titleController: titleController,
              amountController: amountController,
              expenseCurrency: expenseCurrency,
              paidBy: paidBy,
              selectedTravelers: selectedTravelers,
              setModalState: setModalState,
              onCurrencyChanged: (value) {
                expenseCurrency = value;
              },
              onPaidByChanged: (value) {
                paidBy = value;
              },
              onSave: () async {
                final title = titleController.text.trim();

                final amount = double.tryParse(
                  amountController.text.replaceAll(',', '.'),
                );

                if (title.isEmpty ||
                    amount == null ||
                    amount <= 0 ||
                    paidBy == null ||
                    selectedTravelers.isEmpty) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields.'),
                    ),
                  );
                  return;
                }

                try {
                  await _firestore
                      .collection('adventures')
                      .doc(widget.adventureId)
                      .collection('expenses')
                      .add({
                    'title': title,
                    'amount': amount,
                    'currency': expenseCurrency,
                    'paidBy': paidBy,
                    'splitBetween': selectedTravelers.toList(),
                    'createdAt': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;

                  Navigator.of(sheetContext).pop();

                  // Vent til bottom sheet'et er helt væk,
                  // før vi kalder setState() via _loadData().
                  await Future.delayed(const Duration(milliseconds: 300));

                  if (!mounted) return;

                  await _loadData();
                } catch (e) {
                  if (!mounted) return;

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not add expense: $e'),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );

    titleController.dispose();
    amountController.dispose();
  }

  // ============================================================
  // EDIT EXPENSE
  // ============================================================

  Future<void> _showEditExpenseSheet(_Expense expense) async {
    final titleController = TextEditingController(
      text: expense.title,
    );

    final amountController = TextEditingController(
      text: expense.amount.toString(),
    );

    String expenseCurrency = expense.currency;

    String? paidBy = expense.paidBy;

    final selectedTravelers = <String>{
      ...expense.splitBetween,
    };

    // Sørg for at paidBy faktisk findes blandt travelers.
    if (!_travelers.any((traveler) => traveler.id == paidBy)) {
      paidBy = null;
    }

    try {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              return _expenseSheet(
                context: context,
                sheetContext: sheetContext,
                title: 'Edit expense',
                titleController: titleController,
                amountController: amountController,
                expenseCurrency: expenseCurrency,
                paidBy: paidBy,
                selectedTravelers: selectedTravelers,
                setModalState: setModalState,

                onCurrencyChanged: (value) {
                  expenseCurrency = value;
                },

                onPaidByChanged: (value) {
                  paidBy = value;
                },

                onSave: () async {
                  final title = titleController.text.trim();

                  final amount = double.tryParse(
                    amountController.text.replaceAll(',', '.'),
                  );

                  if (title.isEmpty ||
                      amount == null ||
                      amount <= 0 ||
                      paidBy == null ||
                      selectedTravelers.isEmpty) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill in all fields.',
                        ),
                      ),
                    );

                    return;
                  }

                  try {
                    await _firestore
                        .collection('adventures')
                        .doc(widget.adventureId)
                        .collection('expenses')
                        .doc(expense.id)
                        .update({
                      'title': title,
                      'amount': amount,
                      'currency': expenseCurrency,
                      'paidBy': paidBy,
                      'splitBetween': selectedTravelers.toList(),
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    if (!mounted) return;

                    // VIGTIGT:
                    // Vi loader IKKE data her.
                    Navigator.of(sheetContext).pop();
                  } catch (e) {
                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Could not update expense: $e',
                        ),
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      );

      // Bottom sheet'et er NU helt lukket.
      // Først nu loader vi data igen.
      if (!mounted) return;

      await _loadData();
    } finally {
      titleController.dispose();
      amountController.dispose();
    }
  }


  // ============================================================
  // EXPENSE SHEET
  // ============================================================

  Widget _expenseSheet({
    required BuildContext context,
    required BuildContext sheetContext,
    required String title,
    required TextEditingController titleController,
    required TextEditingController amountController,
    required String expenseCurrency,
    required String? paidBy,
    required Set<String> selectedTravelers,
    required StateSetter setModalState,
    required ValueChanged<String> onCurrencyChanged,
    required ValueChanged<String> onPaidByChanged,
    required Future<void> Function() onSave,
  }) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          24,
          20,
          24,
          32,
        ),
        decoration: const BoxDecoration(
          color: DefaultAppColors.background,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: DefaultAppColors.textDark
                        .withValues(alpha: 0.2),
                    borderRadius:
                        BorderRadius.circular(10),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                title,
                style: AppTextStyles.title.copyWith(
                  fontSize: 30,
                ),
              ),

              const SizedBox(height: 24),

              _field(
                controller: titleController,
                hint: 'e.g. Dinner',
              ),

              const SizedBox(height: 14),

              _field(
                controller: amountController,
                hint: 'Amount',
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),

              const SizedBox(height: 14),

              // ==================================================
              // CURRENCY
              // ==================================================

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: DefaultAppColors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _currencies.contains(
                            expenseCurrency)
                        ? expenseCurrency
                        : 'DKK',
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: 'DKK',
                        child: Text('🇩🇰 DKK'),
                      ),
                      DropdownMenuItem(
                        value: 'EUR',
                        child: Text('🇪🇺 EUR'),
                      ),
                      DropdownMenuItem(
                        value: 'USD',
                        child: Text('🇺🇸 USD'),
                      ),
                      DropdownMenuItem(
                        value: 'GBP',
                        child: Text('🇬🇧 GBP'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;

                      setModalState(() {
                        onCurrencyChanged(value);
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Paid by',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: DefaultAppColors.white,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paidBy != null &&
                            _travelers.any(
                              (traveler) =>
                                  traveler.id == paidBy,
                            )
                        ? paidBy
                        : null,
                    hint: const Text(
                      'Select person',
                    ),
                    isExpanded: true,
                    items: _travelers.map((traveler) {
                      return DropdownMenuItem<String>(
                        value: traveler.id,
                        child: Text(traveler.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;

                      setModalState(() {
                        onPaidByChanged(value);
                      });
                    },
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                'Split between',
                style: AppTextStyles.body.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 8),

              ..._travelers.map((traveler) {
                return CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor:
                      DefaultAppColors.terracotta,
                  value: selectedTravelers.contains(
                    traveler.id,
                  ),
                  title: Text(
                    traveler.name,
                    style: AppTextStyles.body,
                  ),
                  onChanged: (value) {
                    setModalState(() {
                      if (value == true) {
                        selectedTravelers.add(
                          traveler.id,
                        );
                      } else {
                        selectedTravelers.remove(
                          traveler.id,
                        );
                      }
                    });
                  },
                );
              }),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        DefaultAppColors.terracotta,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(18),
                    ),
                  ),
                  child: Text(
                    title == 'Edit expense'
                        ? 'Save changes'
                        : 'Add expense',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FIELD
  // ============================================================

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: DefaultAppColors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
      ),
    );
  }

  // ============================================================
  // MARK AS PAID
  // ============================================================

  Future<void> _markAsPaid(
    _Transfer transfer,
  ) async {
    final user =
        FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You need to be logged in.',
          ),
        ),
      );

      return;
    }

    try {
      await _firestore
          .collection('adventures')
          .doc(widget.adventureId)
          .collection('settlements')
          .add({
        'fromUserId': transfer.fromUserId,
        'toUserId': transfer.toUserId,
        'amount': transfer.amount,
        'currency': selectedCurrency,
        'status': 'paid',
        'createdBy': user.uid,
        'paidAt': FieldValue.serverTimestamp(),
      });

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not mark payment as paid: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DELETE EXPENSE
  // ============================================================

  Future<void> _confirmDeleteExpense(
    _Expense expense,
  ) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor:
              DefaultAppColors.background,
          title: const Text(
            'Delete expense?',
          ),
          content: Text(
            'Are you sure you want to delete '
            '"${expense.title}"?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  false,
                );
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  true,
                );
              },
              child: const Text(
                'Delete',
                style: TextStyle(
                  color:
                      DefaultAppColors.terracotta,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await _deleteExpense(expense);
  }

  Future<void> _deleteExpense(
    _Expense expense,
  ) async {
    try {
      await _firestore
          .collection('adventures')
          .doc(widget.adventureId)
          .collection('expenses')
          .doc(expense.id)
          .delete();

      await _loadData();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete expense: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor:
            DefaultAppColors.background,
        appBar: AppBar(
          backgroundColor:
              DefaultAppColors.background,
          elevation: 0,
          title: Text(
            'Split expenses',
            style: AppTextStyles.title,
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(
            color: DefaultAppColors.terracotta,
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor:
            DefaultAppColors.background,
        appBar: AppBar(
          backgroundColor:
              DefaultAppColors.background,
          elevation: 0,
          title: Text(
            'Split expenses',
            style: AppTextStyles.title,
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 50,
                  color:
                      DefaultAppColors.terracotta,
                ),
                const SizedBox(height: 16),
                Text(
                  'Something went wrong',
                  style:
                      AppTextStyles.title.copyWith(
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _loadData,
                  child: const Text(
                    'Try again',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final transfers =
        _calculateTransfers(_balances);

    return Scaffold(
      backgroundColor:
          DefaultAppColors.background,

      appBar: AppBar(
        backgroundColor:
            DefaultAppColors.background,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color:
                DefaultAppColors.terracotta,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Split expenses',
          style: AppTextStyles.title.copyWith(
            fontSize: 28,
          ),
        ),
        centerTitle: true,
      ),

      floatingActionButton:
          FloatingActionButton(
        backgroundColor:
            DefaultAppColors.terracotta,
        onPressed: _showAddExpenseSheet,
        child: const Icon(
          Icons.add,
          color: Colors.white,
        ),
      ),

      body: RefreshIndicator(
        color: DefaultAppColors.terracotta,
        onRefresh: _loadData,
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            20,
            24,
            110,
          ),
          children: [
            // ======================================================
            // CURRENCY
            // ======================================================

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: DefaultAppColors.white,
                borderRadius:
                    BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _currencies.contains(
                          selectedCurrency)
                      ? selectedCurrency
                      : 'DKK',
                  isExpanded: true,
                  items: const [
                    DropdownMenuItem(
                      value: 'DKK',
                      child: Text('🇩🇰 DKK'),
                    ),
                    DropdownMenuItem(
                      value: 'EUR',
                      child: Text('🇪🇺 EUR'),
                    ),
                    DropdownMenuItem(
                      value: 'USD',
                      child: Text('🇺🇸 USD'),
                    ),
                    DropdownMenuItem(
                      value: 'GBP',
                      child: Text('🇬🇧 GBP'),
                    ),
                  ],
                  onChanged: (value) async {
                    if (value == null) {
                      return;
                    }

                    setState(() {
                      selectedCurrency = value;
                    });

                    await _updateBalances();
                  },
                ),
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Overview',
              style: AppTextStyles.title.copyWith(
                fontSize: 34,
              ),
            ),

            const SizedBox(height: 16),

            if (_calculatingBalances)
              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  vertical: 30,
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    color:
                        DefaultAppColors
                            .terracotta,
                  ),
                ),
              )
            else if (transfers.isEmpty)
              _allSettledCard()
            else
              ...transfers.map((transfer) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child:
                      _transferCard(transfer),
                );
              }),

            const SizedBox(height: 30),

            // ======================================================
            // EXPENSES
            // ======================================================

            Text(
              'Expenses',
              style: AppTextStyles.title.copyWith(
                fontSize: 34,
              ),
            ),

            const SizedBox(height: 16),

            if (_expenses.isEmpty)
              _emptyExpenses()
            else
              ..._expenses.map((expense) {
                return Padding(
                  padding:
                      const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child:
                      _expenseCard(expense),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TRANSFER CARD
  // ============================================================

  Widget _transferCard(
    _Transfer transfer,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DefaultAppColors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            '${_getName(transfer.fromUserId)} → '
            '${_getName(transfer.toUserId)}',
            style: AppTextStyles.body.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '${transfer.amount.toStringAsFixed(2)} '
            '$selectedCurrency',
            style: AppTextStyles.body.copyWith(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color:
                  DefaultAppColors.terracotta,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () =>
                  _markAsPaid(transfer),
              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    DefaultAppColors
                        .terracotta,
                side: const BorderSide(
                  color:
                      DefaultAppColors
                          .terracotta,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),
              child: const Text(
                'Mark as paid',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EXPENSE CARD
  // ============================================================

  Widget _expenseCard(
    _Expense expense,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DefaultAppColors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: DefaultAppColors.peach,
                  borderRadius:
                      BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.receipt_long_outlined,
                  color:
                      DefaultAppColors.terracotta,
                ),
              ),

              const SizedBox(width: 14),

              Expanded(
                child: Text(
                  expense.title,
                  style:
                      AppTextStyles.body.copyWith(
                    fontSize: 18,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              Text(
                '${expense.amount.toStringAsFixed(2)} '
                '${expense.currency}',
                style:
                    AppTextStyles.body.copyWith(
                  fontWeight:
                      FontWeight.w600,
                  color:
                      DefaultAppColors
                          .terracotta,
                ),
              ),

              const SizedBox(width: 4),

              // EDIT
              IconButton(
                tooltip: 'Edit',
                icon: const Icon(
                  Icons.edit_outlined,
                  size: 20,
                ),
                color:
                    DefaultAppColors.terracotta,
                onPressed: () =>
                    _showEditExpenseSheet(
                  expense,
                ),
              ),

              // DELETE
              IconButton(
                tooltip: 'Delete',
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                ),
                color:
                    DefaultAppColors.terracotta,
                onPressed: () =>
                    _confirmDeleteExpense(
                  expense,
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Text(
            'Paid by',
            style:
                AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: DefaultAppColors.textDark
                  .withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _getName(expense.paidBy),
            style:
                AppTextStyles.body.copyWith(
              fontSize: 16,
              fontWeight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(height: 14),

          Text(
            'Split between',
            style:
                AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight:
                  FontWeight.w600,
              color: DefaultAppColors.textDark
                  .withValues(alpha: 0.55),
            ),
          ),

          const SizedBox(height: 6),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                expense.splitBetween.map(
              (userId) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color:
                        DefaultAppColors.peach,
                    borderRadius:
                        BorderRadius.circular(
                      20,
                    ),
                  ),
                  child: Text(
                    _getName(userId),
                    style: AppTextStyles.body
                        .copyWith(
                      fontSize: 14,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                );
              },
            ).toList(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ALL SETTLED
  // ============================================================

  Widget _allSettledCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DefaultAppColors.white,
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.check_circle_outline,
            size: 44,
            color:
                DefaultAppColors.terracotta,
          ),

          const SizedBox(height: 12),

          Text(
            'All settled!',
            style:
                AppTextStyles.title.copyWith(
              fontSize: 28,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Everyone is even.',
            style:
                AppTextStyles.body.copyWith(
              color: DefaultAppColors.textDark
                  .withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY EXPENSES
  // ============================================================

  Widget _emptyExpenses() {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 40,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 46,
            color:
                DefaultAppColors.terracotta,
          ),

          const SizedBox(height: 16),

          Text(
            'No expenses yet',
            style:
                AppTextStyles.title.copyWith(
              fontSize: 28,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Tap + to add your first expense.',
            textAlign: TextAlign.center,
            style:
                AppTextStyles.body.copyWith(
              color: DefaultAppColors.textDark
                  .withValues(alpha: 0.60),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// MODELS
// ============================================================

class _Traveler {
  final String id;
  final String name;

  const _Traveler({
    required this.id,
    required this.name,
  });
}

class _Expense {
  final String id;
  final String title;
  final double amount;
  final String currency;
  final String paidBy;
  final List<String> splitBetween;

  const _Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.currency,
    required this.paidBy,
    required this.splitBetween,
  });
}

class _Settlement {
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String currency;
  final String status;

  const _Settlement({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.status,
  });
}

class _Balance {
  final String userId;
  double amount;

  _Balance({
    required this.userId,
    required this.amount,
  });
}

class _Transfer {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const _Transfer({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}