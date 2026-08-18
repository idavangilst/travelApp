import 'package:flutter/material.dart';

import '../services/adventure_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';
import 'adventure_screen.dart';

class JoinAdventureScreen extends StatefulWidget {
  const JoinAdventureScreen({super.key});

  @override
  State<JoinAdventureScreen> createState() =>
      _JoinAdventureScreenState();
}

class _JoinAdventureScreenState
    extends State<JoinAdventureScreen> {
  final TextEditingController _inviteCodeController =
      TextEditingController();

  final AdventureService _adventureService =
      AdventureService();

  bool _isLoading = false;

  @override
  void dispose() {
    _inviteCodeController.dispose();
    super.dispose();
  }

  // ==========================================
  // JOIN ADVENTURE
  // ==========================================

  Future<void> _joinAdventure() async {
    final String inviteCode =
        _inviteCodeController.text.trim().toUpperCase();

    if (inviteCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please enter an invite code.',
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
          await _adventureService.joinAdventure(
        inviteCode: inviteCode,
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
            inviteCode: adventure.inviteCode,
            coverImageUrl: adventure.coverImageUrl,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      String message;

      if (e.toString().contains(
            'Adventure not found',
          )) {
        message =
            'No adventure found with that invite code.';
      } else if (e.toString().contains(
            'already a member',
          )) {
        message =
            'You are already a member of this adventure.';
      } else {
        message =
            'Something went wrong. Please try again.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
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

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // ==========================================
              // BACK BUTTON
              // ==========================================

              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new,
                    color: DefaultAppColors.terracotta,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 35),

              // ==========================================
              // EVARA
              // ==========================================

              Text(
                'EVARA',
                style: AppTextStyles.title.copyWith(
                  fontSize: 38,
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // TITLE
              // ==========================================

              Text(
                'Join an adventure',
                style: AppTextStyles.title.copyWith(
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'Enter the invite code you received.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 17,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 45),

              // ==========================================
              // INVITE CODE
              // ==========================================

              EvaraTextField(
                label: 'Invite code',
                hint: 'e.g. EVR-X7K2',
                controller: _inviteCodeController,
                keyboardType: TextInputType.text,
              ),

              const SizedBox(height: 35),

              // ==========================================
              // JOIN BUTTON
              // ==========================================

              _isLoading
                  ? const CircularProgressIndicator(
                      color:
                          DefaultAppColors.terracotta,
                    )
                  : PrimaryButton(
                      text: 'Join Adventure',
                      onPressed: _joinAdventure,
                    ),

              const SizedBox(height: 35),

              // ==========================================
              // INFORMATION
              // ==========================================

              Text(
                'Ask the person who created the adventure '
                'for their invite code.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 15,
                  color: DefaultAppColors.textDark
                      .withValues(alpha: 0.65),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
