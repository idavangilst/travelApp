import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import 'create_adventure_screen.dart';
import 'join_adventure_screen.dart';
import 'my_adventures_screen.dart';

class AdventureHubScreen extends StatelessWidget {
  const AdventureHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user =
        FirebaseAuth.instance.currentUser;

    final String name =
        user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : 'Traveler';

    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 55),

              // ==========================================
              // EVARA
              // ==========================================

              Text(
                'EVARA',
                style: AppTextStyles.title.copyWith(
                  fontSize: 32,
                ),
              ),

              const SizedBox(height: 50),

              // ==========================================
              // WELCOME
              // ==========================================

              Text(
                'Welcome back, $name',
                style: AppTextStyles.body.copyWith(
                  fontSize: 25,
                  color: DefaultAppColors.terracotta,
                ),
              ),

              const SizedBox(height: 12),

              Text(
                'Where will you go next?',
                style: AppTextStyles.body.copyWith(
                  fontSize: 20,
                  color: DefaultAppColors.textDark,
                ),
              ),

              const Spacer(),

              // ==========================================
              // CREATE ADVENTURE
              // ==========================================

              PrimaryButton(
                text: 'Create Adventure',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const CreateAdventureScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
              
              
              // JOIN ADVENTURE
              PrimaryButton(
                text: 'Join Adventure',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const JoinAdventureScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // MY ADVENTURES
              PrimaryButton(
                text: 'My Adventures',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MyAdventuresScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 35),

              // LOG OUT
              Center(
                child: TextButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.pop(context);
                  },
                  child: Text(
                    'Log out',
                    style: TextStyle(
                      color:
                          DefaultAppColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
