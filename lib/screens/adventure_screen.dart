import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class AdventureScreen extends StatelessWidget {
  final String adventureName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;

  const AdventureScreen({
    super.key,
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Back button
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

              const SizedBox(height: 28),

              // Adventure name
              Text(
                adventureName,
                style: AppTextStyles.title.copyWith(
                  fontSize: 36,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              // Destination
              Text(
                destination,
                style: AppTextStyles.body.copyWith(
                  fontSize: 25,
                  color: DefaultAppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              // Dates
              Text(
                '${_formatDate(startDate)} – ${_formatDate(endDate)}',
                style: AppTextStyles.body.copyWith(
                  fontSize: 18,
                  color: DefaultAppColors.textDark.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 38),

              // Adventure options
              Expanded(
                child: Column(
                  children: [
                    _AdventureOption(
                      icon: Icons.photo_library_outlined,
                      title: 'Memories',
                      subtitle: 'Add photos and memories',
                    ),

                    const SizedBox(height: 18),

                    _AdventureOption(
                      icon: Icons.map_outlined,
                      title: 'Itinerary',
                      subtitle: 'Plan your adventure',
                    ),

                    const SizedBox(height: 18),

                    _AdventureOption(
                      icon: Icons.book_outlined,
                      title: 'Travel diary',
                      subtitle: 'Write about your journey',
                    ),

                    const SizedBox(height: 18),

                    _AdventureOption(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Expenses',
                      subtitle: 'Keep track of your spending',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdventureOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _AdventureOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: DefaultAppColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 30,
            color: DefaultAppColors.terracotta,
          ),

          const SizedBox(width: 18),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.body.copyWith(
                  fontSize: 19,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14,
                  color: DefaultAppColors.textDark.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}