import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'create_adventure_screen.dart';
import 'join_adventure_screen.dart';
import 'my_adventures_screen.dart';

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
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 28),

              // ==========================================
              // TOP BAR
              // ==========================================

              Row(
                children: [
                  Text(
                    'EVARA',
                    style: AppTextStyles.title.copyWith(
                      fontSize: 29,
                      letterSpacing: 2,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: DefaultAppColors.peach,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: DefaultAppColors.terracotta,
                      size: 25,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 52),

              // ==========================================
              // WELCOME
              // ==========================================

              Text(
                'Welcome back, $name',
                style: AppTextStyles.body.copyWith(
                  fontSize: 27,
                  color: DefaultAppColors.terracotta,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                'Where will you go next?',
                style: AppTextStyles.body.copyWith(
                  fontSize: 21,
                  color: DefaultAppColors.textDark,
                ),
              ),

              const SizedBox(height: 38),

              // ==========================================
              // CREATE ADVENTURE
              // ==========================================

              _AdventureActionCard(
                icon: Icons.add_location_alt_outlined,
                title: 'Create Adventure',
                subtitle: 'Start a new journey',
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

              const SizedBox(height: 14),

              // ==========================================
              // JOIN ADVENTURE
              // ==========================================

              _AdventureActionCard(
                icon: Icons.group_add_outlined,
                title: 'Join Adventure',
                subtitle: 'Join a journey with friends',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const JoinAdventureScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 14),

              // ==========================================
              // MY ADVENTURES
              // ==========================================

              _AdventureActionCard(
                icon: Icons.luggage_outlined,
                title: 'My Adventures',
                subtitle: 'See your saved journeys',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          const MyAdventuresScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              // ==========================================
              // LOG OUT
              // ==========================================

              Center(
                child: TextButton.icon(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();

                    if (!context.mounted) return;

                    Navigator.pop(context);
                  },
                  icon: const Icon(
                    Icons.logout_outlined,
                    size: 18,
                    color: DefaultAppColors.terracotta,
                  ),
                  label: Text(
                    'Log out',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: DefaultAppColors.terracotta,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

// ======================================================
// ADVENTURE ACTION CARD
// ======================================================

class _AdventureActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdventureActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 21,
          ),
          decoration: BoxDecoration(
            color: DefaultAppColors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Row(
            children: [
              // ICON
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: DefaultAppColors.peach,
                  borderRadius: BorderRadius.circular(19),
                ),
                child: Icon(
                  icon,
                  color: DefaultAppColors.terracotta,
                  size: 29,
                ),
              ),

              const SizedBox(width: 17),

              // TEXT
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: DefaultAppColors.textDark.withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ARROW
              const Icon(
                Icons.arrow_forward_ios,
                size: 17,
                color: DefaultAppColors.terracotta,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
