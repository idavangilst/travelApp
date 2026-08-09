import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/evara_feature_card.dart';
import 'create_adventure_screen.dart';

class AdventureHubScreen extends StatelessWidget {
  const AdventureHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    final String name =
        user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : 'Traveler';

    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 45),

                // ==========================================
                // EVARA
                // ==========================================

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'EVARA',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 32,
                    ),
                  ),
                ),

                const SizedBox(height: 45),

                // ==========================================
                // WELCOME
                // ==========================================

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Welcome back, $name',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 27,
                      color: DefaultAppColors.terracotta,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'Where will you go next?',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 20,
                      color: DefaultAppColors.textDark,
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                // ==========================================
                // CREATE ADVENTURE
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.flight_takeoff_outlined,
                  title: 'Create Adventure',
                  subtitle: 'Start planning a new journey',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const CreateAdventureScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 18),

                // ==========================================
                // JOIN ADVENTURE
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.group_add_outlined,
                  title: 'Join Adventure',
                  subtitle: 'Join a journey with your friends',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 18),

                // ==========================================
                // MY ADVENTURES
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.map_outlined,
                  title: 'My Adventures',
                  subtitle: 'Explore your upcoming journeys',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 40),

                // ==========================================
                // LOG OUT
                // ==========================================

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
                        color: DefaultAppColors.terracotta,
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
      ),
    );
  }
}
