import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/evara_feature_card.dart';

class AdventureScreen extends StatelessWidget {
  final String adventureId;
  final String adventureName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  const AdventureScreen({
    super.key,
    required this.adventureId,
    required this.adventureName,
    required this.destination,
    required this.startDate,
    required this.endDate,
  });

  String _formatDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // ==========================================
                // BACK BUTTON
                // ==========================================

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: DefaultAppColors.terracotta,
                      size: 22,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 25),

                // ==========================================
                // ADVENTURE NAME
                // ==========================================

                Text(
                  adventureName,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 36,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                // ==========================================
                // DESTINATION
                // ==========================================

                Text(
                  destination,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 25,
                    color: DefaultAppColors.textDark,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                // ==========================================
                // DATES
                // ==========================================

                Text(
                  '${_formatDate(startDate)} – ${_formatDate(endDate)}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 18,
                    color: DefaultAppColors.textDark.withValues(
                      alpha: 0.7,
                    ),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 35),

                // ==========================================
                // MEMORIES
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.photo_library_outlined,
                  title: 'Memories',
                  subtitle:
                      'Add photos and save your favorite moments',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 18),

                // ==========================================
                // ITINERARY
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.map_outlined,
                  title: 'Itinerary',
                  subtitle:
                      'Plan what you will do each day',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 18),

                // ==========================================
                // TRAVEL DIARY
                // ==========================================

                EvaraFeatureCard(
                  icon: Icons.book_outlined,
                  title: 'Travel Diary',
                  subtitle:
                      'Write down the story of your journey',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 18),

                // ==========================================
                // EXPENSES
                // ==========================================

                EvaraFeatureCard(
                  icon:
                      Icons.account_balance_wallet_outlined,
                  title: 'Expenses',
                  subtitle:
                      'Keep track of what you spend',
                  onTap: () {
                    // Coming next
                  },
                ),

                const SizedBox(height: 35),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
