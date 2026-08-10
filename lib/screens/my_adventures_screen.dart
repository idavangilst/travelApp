import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/adventure.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'adventure_screen.dart';
import 'create_adventure_screen.dart';

class MyAdventuresScreen extends StatelessWidget {
  const MyAdventuresScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: DefaultAppColors.background,
        body: Center(
          child: Text(
            'Please log in to see your adventures.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              // ==========================================
              // BACK BUTTON
              // ==========================================

              IconButton(
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

              const SizedBox(height: 20),

              // ==========================================
              // TITLE
              // ==========================================

              Text(
                'My Adventures',
                style: AppTextStyles.title.copyWith(
                  fontSize: 36,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Your journeys, all in one place.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 17,
                ),
              ),

              const SizedBox(height: 30),

              // ==========================================
              // ADVENTURES
              // ==========================================

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<Map<String, dynamic>>>(
                  stream: FirebaseFirestore.instance
                      .collection('adventures')
                      .where(
                        'memberIds',
                        arrayContains: user.uid,
                      )
                      .orderBy(
                        'startDate',
                        descending: false,
                      )
                      .snapshots(),

                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: DefaultAppColors.terracotta,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Something went wrong while loading your adventures.',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 17,
                          ),
                        ),
                      );
                    }

                    if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return _EmptyAdventures(
                        onCreateAdventure: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const CreateAdventureScreen(),
                            ),
                          );
                        },
                      );
                    }

                    final adventures = snapshot.data!.docs
                        .map(
                          (document) =>
                              Adventure.fromFirestore(document),
                        )
                        .toList();

                    return ListView.separated(
                      padding: const EdgeInsets.only(
                        bottom: 30,
                      ),
                      itemCount: adventures.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 18),
                      itemBuilder: (context, index) {
                        final Adventure adventure =
                            adventures[index];

                        return _AdventureCard(
                          adventure: adventure,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    AdventureScreen(
                                  adventureId:
                                      adventure.id,
                                  adventureName:
                                      adventure.name,
                                  destination:
                                      adventure.destination,
                                  startDate:
                                      adventure.startDate,
                                  endDate:
                                      adventure.endDate,
                                  inviteCode:
                                      adventure.inviteCode,
                                  coverImageUrl:
                                      adventure.coverImageUrl,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================================
// ADVENTURE CARD
// ==========================================================

class _AdventureCard extends StatelessWidget {
  final Adventure adventure;
  final VoidCallback onTap;

  const _AdventureCard({
    required this.adventure,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: DefaultAppColors.white,
      borderRadius: BorderRadius.circular(24),

      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),

        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // ==========================================
              // COVER IMAGE
              // ==========================================

              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  width: 75,
                  height: 75,
                  child: adventure.coverImageUrl != null &&
                          adventure.coverImageUrl!.isNotEmpty
                      ? Image.network(
                          adventure.coverImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) {
                            return _FallbackAdventureIcon();
                          },
                        )
                      : _FallbackAdventureIcon(),
                ),
              ),

              const SizedBox(width: 18),

              // ==========================================
              // INFORMATION
              // ==========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      adventure.name,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 21,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      adventure.destination,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 17,
                        color:
                            DefaultAppColors.terracotta,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${_formatDate(adventure.startDate)} – ${_formatDate(adventure.endDate)}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 14,
                        color: DefaultAppColors.textDark
                            .withValues(alpha: 0.65),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // ==========================================
              // ARROW
              // ==========================================

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

// ==========================================================
// FALLBACK ICON
// ==========================================================

class _FallbackAdventureIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: DefaultAppColors.peach,
      child: const Center(
        child: Icon(
          Icons.flight_takeoff_outlined,
          color: DefaultAppColors.terracotta,
          size: 29,
        ),
      ),
    );
  }
}

// ==========================================================
// EMPTY STATE
// ==========================================================

class _EmptyAdventures extends StatelessWidget {
  final VoidCallback onCreateAdventure;

  const _EmptyAdventures({
    required this.onCreateAdventure,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: DefaultAppColors.peach,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.public_outlined,
              size: 45,
              color: DefaultAppColors.terracotta,
            ),
          ),

          const SizedBox(height: 25),

          Text(
            'No adventures yet',
            style: AppTextStyles.title.copyWith(
              fontSize: 28,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 8),

          Text(
            'Create your first adventure\nand start planning your journey.',
            style: AppTextStyles.body.copyWith(
              fontSize: 17,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 28),

          SizedBox(
            width: 220,
            height: 55,
            child: ElevatedButton(
              onPressed: onCreateAdventure,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    DefaultAppColors.terracotta,
                foregroundColor:
                    DefaultAppColors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Create Adventure',
                style: AppTextStyles.button.copyWith(
                  color: DefaultAppColors.white,
                  fontSize: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}