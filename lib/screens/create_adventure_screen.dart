import 'package:flutter/material.dart';

import '../services/adventure_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';
import 'adventure_screen.dart';

class CreateAdventureScreen extends StatefulWidget {
  const CreateAdventureScreen({super.key});

  @override
  State<CreateAdventureScreen> createState() =>
      _CreateAdventureScreenState();
}

class _CreateAdventureScreenState
    extends State<CreateAdventureScreen> {
  final AdventureService _adventureService =
      AdventureService();

  final TextEditingController _adventureNameController =
      TextEditingController();

  final TextEditingController _destinationController =
      TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  bool _isLoading = false;

  @override
  void dispose() {
    _adventureNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // ==========================================
  // START DATE
  // ==========================================

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        // Reset end date if it is before the new start date
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  // ==========================================
  // END DATE
  // ==========================================

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start date first.',
          ),
        ),
      );

      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // ==========================================
  // CREATE ADVENTURE
  // ==========================================

  Future<void> _createAdventure() async {
    final String adventureName =
        _adventureNameController.text.trim();

    final String destination =
        _destinationController.text.trim();

    // Validate fields
    if (adventureName.isEmpty ||
        destination.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final adventure =
          await _adventureService.createAdventure(
        adventureName: adventureName,
        destination: destination,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdventureScreen(
            adventureId: adventure.id,
            adventureName: adventure.name,
            destination: adventure.destination,
            startDate: adventure.startDate,
            endDate: adventure.endDate,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while creating your adventure.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      appBar: AppBar(
        backgroundColor: DefaultAppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: DefaultAppColors.terracotta,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ==========================================
                // TITLE
                // ==========================================

                Text(
                  'Create your adventure',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 34,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Let's start planning your trip.",
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                // ==========================================
                // ADVENTURE NAME
                // ==========================================

                EvaraTextField(
                  label: 'Adventure name',
                  hint: 'e.g. Summer in Italy',
                  controller: _adventureNameController,
                ),

                const SizedBox(height: 25),

                // ==========================================
                // DESTINATION
                // ==========================================

                EvaraTextField(
                  label: 'Destination',
                  hint: 'Where are you going?',
                  controller: _destinationController,
                ),

                const SizedBox(height: 25),

                // ==========================================
                // START DATE
                // ==========================================

                Text(
                  'Start date',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: DefaultAppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _selectStartDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: DefaultAppColors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: DefaultAppColors.terracotta,
                        ),

                        const SizedBox(width: 14),

                        Text(
                          _startDate == null
                              ? 'Select start date'
                              : '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}',
                          style: TextStyle(
                            fontSize: 17,
                            color: _startDate == null
                                ? DefaultAppColors.textDark
                                    .withValues(alpha: 0.45)
                                : DefaultAppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ==========================================
                // END DATE
                // ==========================================

                GestureDetector(
                  onTap: _selectEndDate,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      color: DefaultAppColors.white,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: DefaultAppColors.terracotta,
                        ),

                        const SizedBox(width: 14),

                        Text(
                          _endDate == null
                              ? 'Select end date'
                              : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                          style: TextStyle(
                            fontSize: 17,
                            color: _endDate == null
                                ? DefaultAppColors.textDark
                                    .withValues(alpha: 0.45)
                                : DefaultAppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ==========================================
                // CONTINUE
                // ==========================================

                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: DefaultAppColors.terracotta,
                        )
                      : PrimaryButton(
                          text: 'Continue',
                          onPressed: _createAdventure,
                        ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}