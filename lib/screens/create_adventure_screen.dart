import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';

class CreateAdventureScreen extends StatefulWidget {
  const CreateAdventureScreen({super.key});

  @override
  State<CreateAdventureScreen> createState() =>
      _CreateAdventureScreenState();
}

class _CreateAdventureScreenState
    extends State<CreateAdventureScreen> {
  final TextEditingController _adventureNameController =
      TextEditingController();

  final TextEditingController _destinationController =
      TextEditingController();

  @override
  void dispose() {
    _adventureNameController.dispose();
    _destinationController.dispose();
    super.dispose();
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
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                Text(
                  'Create your adventure',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 34,
                  ),
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

                const SizedBox(height: 40),

                PrimaryButton(
                  text: 'Continue',
                  onPressed: () {
                    print(
                      'Adventure: ${_adventureNameController.text}',
                    );

                    print(
                      'Destination: ${_destinationController.text}',
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