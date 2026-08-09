import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';
import 'adventure_screen.dart';

class CreateAdventureScreen extends StatefulWidget {
  const CreateAdventureScreen({super.key});

  @override
  State<CreateAdventureScreen> createState() => _CreateAdventureScreenState();
}

class _CreateAdventureScreenState extends State<CreateAdventureScreen> {
  final TextEditingController _adventureNameController =
      TextEditingController();

  final TextEditingController _destinationController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void dispose() {
    _adventureNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

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

        //If enddate before startdate we reset
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a start date first.')),
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

                Text(
                  'Create your adventure',
                  style: AppTextStyles.title.copyWith(fontSize: 34),
                ),

                const SizedBox(height: 10),

                Text(
                  "Let's start planning your trip.",
                  style: TextStyle(
                    fontSize: 16,
                    color: DefaultAppColors.textDark,
                  ),
                ),

                const SizedBox(height: 40),

                // Adventure name
                EvaraTextField(
                  label: 'Adventure name',
                  hint: 'e.g. Summer in Italy',
                  controller: _adventureNameController,
                ),

                const SizedBox(height: 25),

                // Destination
                EvaraTextField(
                  label: 'Destination',
                  hint: 'Where are you going?',
                  controller: _destinationController,
                ),

                const SizedBox(height: 25),

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
                              ? DefaultAppColors.textDark.withValues(alpha: 0.45)
                              : DefaultAppColors.textDark,
                          ),  
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

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
                                ? DefaultAppColors.textDark.withValues(alpha: 0.45)
                                : DefaultAppColors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                PrimaryButton(
                  text: 'Continue',
                  onPressed: () {
                    if (_adventureNameController.text.trim().isEmpty ||
                        _destinationController.text.trim().isEmpty ||
                        _startDate == null ||
                        _endDate == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please fill in all fields.'),
                        ),
                      );
                      return;
                    }

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AdventureScreen(
                          adventureName: _adventureNameController.text.trim(),
                          destination: _destinationController.text.trim(),
                          startDate: _startDate!,
                          endDate: _endDate!,
                        ),
                      ),
                    );
                  },
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
