import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'memories_screen.dart';

class AdventureScreen extends StatefulWidget {
  final String adventureId;
  final String adventureName;
  final String destination;
  final DateTime startDate;
  final DateTime endDate;
  final String inviteCode;
  final String? coverImageUrl;

  const AdventureScreen({
    super.key,
    required this.adventureId,
    required this.adventureName,
    required this.destination,
    required this.startDate,
    required this.endDate,
    required this.inviteCode,
    this.coverImageUrl,
  });

  @override
  State<AdventureScreen> createState() =>
      _AdventureScreenState();
}

class _AdventureScreenState extends State<AdventureScreen> {
  final ScrollController _scrollController =
      ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ==========================================
  // DATE FORMAT
  // ==========================================

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

  // ==========================================
  // INVITE POPUP
  // ==========================================

  void _showInviteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: DefaultAppColors.background,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: DefaultAppColors.peach,
                    borderRadius:
                        BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_outlined,
                    size: 30,
                    color: DefaultAppColors.terracotta,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Invite travelers',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 28,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Share this code with friends\n'
                  'you want to join your adventure.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: DefaultAppColors.textDark
                        .withValues(alpha: 0.70),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // INVITE CODE
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: DefaultAppColors.white,
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.inviteCode,
                          style: AppTextStyles.body.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color:
                                DefaultAppColors.terracotta,
                            letterSpacing: 2,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      IconButton(
                        tooltip: 'Copy code',
                        icon: const Icon(
                          Icons.copy_outlined,
                          color:
                              DefaultAppColors.terracotta,
                        ),
                        onPressed: () async {
                          await Clipboard.setData(
                            ClipboardData(
                              text: widget.inviteCode,
                            ),
                          );

                          if (!context.mounted) return;

                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Invite code copied!'),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          DefaultAppColors.terracotta,
                      foregroundColor:
                          DefaultAppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      'Done',
                      style: AppTextStyles.button.copyWith(
                        color: DefaultAppColors.white,
                        fontSize: 19,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // TRAVELERS POPUP
  // ==========================================

  void _showTravelersDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: DefaultAppColors.background,
              borderRadius: BorderRadius.circular(30),
            ),
            child: StreamBuilder<
                DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('adventures')
                  .doc(widget.adventureId)
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(
                      child: CircularProgressIndicator(
                        color:
                            DefaultAppColors.terracotta,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError ||
                    !snapshot.hasData ||
                    !snapshot.data!.exists) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 45,
                        color:
                            DefaultAppColors.terracotta,
                      ),

                      const SizedBox(height: 15),

                      Text(
                        'Could not load travelers.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 17,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 20),

                      _DialogButton(
                        text: 'Done',
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  );
                }

                final data =
                    snapshot.data!.data();

                final List<String> memberIds =
                    List<String>.from(
                  data?['memberIds'] ?? [],
                );

                final String ownerId =
                    data?['ownerId'] ?? '';

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // HEADER
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: DefaultAppColors.peach,
                        borderRadius:
                            BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 31,
                        color:
                            DefaultAppColors.terracotta,
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      'Travelers',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 28,
                      ),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      '${memberIds.length} '
                      '${memberIds.length == 1 ? 'traveler' : 'travelers'}',
                      style: AppTextStyles.body.copyWith(
                        fontSize: 15,
                        color: DefaultAppColors.textDark
                            .withValues(alpha: 0.60),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // TRAVELER LIST
                    if (memberIds.isEmpty)
                      Text(
                        'No travelers yet.',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 16,
                        ),
                      )
                    else
                      ConstrainedBox(
                        constraints:
                            const BoxConstraints(
                          maxHeight: 280,
                        ),
                        child: ListView.separated(
                          shrinkWrap: true,
                          itemCount: memberIds.length,
                          separatorBuilder:
                              (context, index) =>
                                  const SizedBox(height: 10),
                          itemBuilder:
                              (context, index) {
                            final String memberId =
                                memberIds[index];

                            return _TravelerTile(
                              userId: memberId,
                              isCreator:
                                  memberId == ownerId,
                            );
                          },
                        ),
                      ),

                    const SizedBox(height: 22),

                    _DialogButton(
                      text: 'Done',
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(),

          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 28),

            child: Column(
              children: [
                const SizedBox(height: 10),

                // ==========================================
                // TOP BAR
                // ==========================================

                Row(
                  children: [
                    IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(
                        Icons.arrow_back_ios_new,
                        color:
                            DefaultAppColors.terracotta,
                        size: 21,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),

                    const Spacer(),

                    Text(
                      'EVARA',
                      style: AppTextStyles.title.copyWith(
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ==========================================
                // ADVENTURE HEADER
                // ==========================================

                Text(
                  widget.adventureName,
                  style: AppTextStyles.title.copyWith(
                    fontSize: 38,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 6),

                Text(
                  widget.destination,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 23,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 5),

                Text(
                  '${_formatDate(widget.startDate)} – '
                  '${_formatDate(widget.endDate)}',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: DefaultAppColors.textDark
                        .withValues(alpha: 0.60),
                  ),
                  textAlign: TextAlign.center,
                ),

                // ==========================================
                // ANIMATED COVER IMAGE
                // ==========================================

                if (widget.coverImageUrl != null &&
                    widget.coverImageUrl!.isNotEmpty) ...[
                  const SizedBox(height: 20),

                  AnimatedBuilder(
                    animation: _scrollController,

                    builder: (context, child) {
                      final double offset =
                          _scrollController.hasClients
                              ? _scrollController.offset
                              : 0;

                      // How much the image shrinks.
                      final double shrinkAmount =
                          offset.clamp(0.0, 120.0);

                      final double imageHeight =
                          (190 - shrinkAmount * 0.55)
                              .clamp(90.0, 190.0);

                      // Fade out gradually.
                      final double opacity =
                          (1 -
                                  (shrinkAmount / 150))
                              .clamp(0.0, 1.0);

                      return Opacity(
                        opacity: opacity,

                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(24),

                          child: SizedBox(
                            width: double.infinity,
                            height: imageHeight,

                            child: Image.network(
                              widget.coverImageUrl!,
                              fit: BoxFit.cover,

                              errorBuilder:
                                  (
                                context,
                                error,
                                stackTrace,
                              ) {
                                return Container(
                                  width: double.infinity,
                                  height: imageHeight,
                                  decoration:
                                      BoxDecoration(
                                    color:
                                        DefaultAppColors
                                            .peach,
                                    borderRadius:
                                        BorderRadius
                                            .circular(24),
                                  ),
                                  child: const Icon(
                                    Icons
                                        .image_not_supported_outlined,
                                    size: 40,
                                    color:
                                        DefaultAppColors
                                            .terracotta,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 22),

                // ==========================================
                // TRAVELERS + INVITE
                // ==========================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    // Travelers
                    GestureDetector(
                      onTap: () {
                        _showTravelersDialog(context);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DefaultAppColors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: DefaultAppColors
                                .terracotta
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.people_outline,
                              size: 17,
                              color: DefaultAppColors
                                  .terracotta,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              'Travelers',
                              style:
                                  AppTextStyles.body
                                      .copyWith(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    DefaultAppColors
                                        .terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Invite
                    GestureDetector(
                      onTap: () {
                        _showInviteDialog(context);
                      },
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: DefaultAppColors.white,
                          borderRadius:
                              BorderRadius.circular(20),
                          border: Border.all(
                            color: DefaultAppColors
                                .terracotta
                                .withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons
                                  .person_add_alt_1_outlined,
                              size: 17,
                              color: DefaultAppColors
                                  .terracotta,
                            ),

                            const SizedBox(width: 6),

                            Text(
                              'Invite',
                              style:
                                  AppTextStyles.body
                                      .copyWith(
                                fontSize: 15,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    DefaultAppColors
                                        .terracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ==========================================
                // ADVENTURE OPTIONS
                // ==========================================

                _AdventureOption(
                  icon: Icons.photo_library_outlined,
                  title: 'Memories',
                  subtitle: 'Save your favorite moments and photos',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemoriesScreen(
                          adventureId: widget.adventureId,
                          adventureName: widget.adventureName,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 15),

                _AdventureOption(
                  icon: Icons.map_outlined,
                  title: 'Itinerary',
                  subtitle:
                      'Plan your days and places to visit',
                  onTap: () {},
                ),

                const SizedBox(height: 15),

                _AdventureOption(
                  icon: Icons.book_outlined,
                  title: 'Travel diary',
                  subtitle:
                      'Write down the moments you want to remember',
                  onTap: () {},
                ),

                const SizedBox(height: 15),

                _AdventureOption(
                  icon:
                      Icons.account_balance_wallet_outlined,
                  title: 'Expenses',
                  subtitle:
                      'Keep track of what you spend together',
                  onTap: () {},
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

// ======================================================
// TRAVELER TILE
// ======================================================

class _TravelerTile extends StatelessWidget {
  final String userId;
  final bool isCreator;

  const _TravelerTile({
    required this.userId,
    required this.isCreator,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<
        DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get(),

      builder: (context, snapshot) {
        String name = 'Traveler';

        if (snapshot.hasData &&
            snapshot.data!.exists) {
          final data = snapshot.data!.data();

          if (data != null &&
              data['name'] != null &&
              data['name']
                  .toString()
                  .trim()
                  .isNotEmpty) {
            name = data['name'].toString();
          }
        }

        return Container(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 12,
          ),
          decoration: BoxDecoration(
            color: DefaultAppColors.white,
            borderRadius: BorderRadius.circular(18),
          ),

          child: Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: DefaultAppColors.peach,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 21,
                  color:
                      DefaultAppColors.terracotta,
                ),
              ),

              const SizedBox(width: 12),

              // Name
              Expanded(
                child: Text(
                  name,
                  style:
                      AppTextStyles.body.copyWith(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),

              // Creator badge
              if (isCreator)
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color:
                        DefaultAppColors.peach,
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Creator',
                    style:
                        AppTextStyles.body.copyWith(
                      fontSize: 12,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          DefaultAppColors
                              .terracotta,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ======================================================
// DIALOG BUTTON
// ======================================================

class _DialogButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _DialogButton({
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,

      child: ElevatedButton(
        onPressed: onPressed,

        style: ElevatedButton.styleFrom(
          backgroundColor:
              DefaultAppColors.terracotta,
          foregroundColor:
              DefaultAppColors.white,
          elevation: 0,

          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(28),
          ),
        ),

        child: Text(
          text,
          style:
              AppTextStyles.button.copyWith(
            color:
                DefaultAppColors.white,
            fontSize: 19,
          ),
        ),
      ),
    );
  }
}

// ======================================================
// ADVENTURE OPTION
// ======================================================

class _AdventureOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdventureOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,

      child: Container(
        width: double.infinity,

        padding:
            const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        decoration: BoxDecoration(
          color: DefaultAppColors.white,
          borderRadius:
              BorderRadius.circular(24),
        ),

        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                color:
                    DefaultAppColors.peach,
                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: Icon(
                icon,
                size: 26,
                color:
                    DefaultAppColors
                        .terracotta,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style:
                        AppTextStyles.body
                            .copyWith(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 3),

                  Text(
                    subtitle,
                    style:
                        AppTextStyles.body
                            .copyWith(
                      fontSize: 14,
                      color:
                          DefaultAppColors
                              .textDark
                              .withValues(
                        alpha: 0.62,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color:
                  DefaultAppColors
                      .terracotta,
            ),
          ],
        ),
      ),
    );
  }
}