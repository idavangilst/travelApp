import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class MemoriesScreen extends StatefulWidget {
  final String adventureId;
  final String adventureName;

  const MemoriesScreen({
    super.key,
    required this.adventureId,
    required this.adventureName,
  });

  @override
  State<MemoriesScreen> createState() =>
      _MemoriesScreenState();
}

class _MemoriesScreenState
    extends State<MemoriesScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  // ==========================================
  // ADD MEMORY POPUP
  // ==========================================

  void _showAddMemoryDialog() {
    final TextEditingController titleController =
        TextEditingController();

    final ImagePicker imagePicker =
        ImagePicker();

    final List<File> selectedImages = [];

    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: !isUploading,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            // ==========================================
            // PICK IMAGES
            // ==========================================

            Future<void> pickImages() async {
              try {
                final List<XFile> pickedImages =
                    await imagePicker.pickMultiImage(
                  imageQuality: 85,
                  maxWidth: 1600,
                );

                if (pickedImages.isEmpty) {
                  return;
                }

                setDialogState(() {
                  for (final image
                      in pickedImages) {
                    final File file =
                        File(image.path);

                    final bool alreadyAdded =
                        selectedImages.any(
                      (existingImage) =>
                          existingImage.path ==
                          file.path,
                    );

                    if (!alreadyAdded) {
                      selectedImages.add(file);
                    }
                  }
                });
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Something went wrong while selecting photos.',
                    ),
                  ),
                );
              }
            }

            // ==========================================
            // REMOVE IMAGE
            // ==========================================

            void removeImage(int index) {
              setDialogState(() {
                selectedImages.removeAt(index);
              });
            }

            // ==========================================
            // SAVE MEMORY
            // ==========================================

            Future<void> saveMemory() async {
              final String title =
                  titleController.text.trim();

              if (title.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please give your memory a title.',
                    ),
                  ),
                );

                return;
              }

              if (selectedImages.isEmpty) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please add at least one photo.',
                    ),
                  ),
                );

                return;
              }

              setDialogState(() {
                isUploading = true;
              });

              try {
                final User? user =
                    FirebaseAuth.instance.currentUser;

                if (user == null) {
                  throw Exception(
                    'No user is currently signed in.',
                  );
                }

                // ==========================================
                // CREATE MEMORY DOCUMENT
                // ==========================================

                final DocumentReference
                    memoryReference =
                    await _firestore
                        .collection('adventures')
                        .doc(widget.adventureId)
                        .collection('memories')
                        .add({
                  'title': title,
                  'createdBy': user.uid,
                  'createdAt':
                      FieldValue.serverTimestamp(),
                  'imageUrls': [],
                });

                final List<String> imageUrls = [];

                // ==========================================
                // UPLOAD EACH IMAGE
                // ==========================================

                for (int i = 0;
                    i < selectedImages.length;
                    i++) {
                  final File image =
                      selectedImages[i];

                  final Reference storageReference =
                      FirebaseStorage.instance
                          .ref()
                          .child(
                            'adventure_memories',
                          )
                          .child(
                            widget.adventureId,
                          )
                          .child(
                            memoryReference.id,
                          )
                          .child(
                            '${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );

                  debugPrint(
                    'Uploading memory image: '
                    '${storageReference.fullPath}',
                  );

                  await storageReference.putFile(
                    image,
                    SettableMetadata(
                      contentType: 'image/jpeg',
                    ),
                  );

                  final String imageUrl =
                      await storageReference
                          .getDownloadURL();

                  imageUrls.add(imageUrl);
                }

                // ==========================================
                // SAVE IMAGE URLS
                // ==========================================

                await memoryReference.update({
                  'imageUrls': imageUrls,
                });

                if (!context.mounted) return;

                Navigator.pop(context);

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Memory added! ❤️',
                    ),
                  ),
                );
              } catch (e) {
                debugPrint(
                  'MEMORY UPLOAD ERROR: $e',
                );

                if (!context.mounted) return;

                setDialogState(() {
                  isUploading = false;
                });

                ScaffoldMessenger.of(context)
                    .showSnackBar(
                  SnackBar(
                    content: Text(
                      'Something went wrong: $e',
                    ),
                  ),
                );
              }
            }

            return Dialog(
              backgroundColor:
                  Colors.transparent,

              insetPadding:
                  const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),

              child: Container(
                constraints:
                    const BoxConstraints(
                  maxHeight: 700,
                ),

                padding:
                    const EdgeInsets.all(26),

                decoration: BoxDecoration(
                  color:
                      DefaultAppColors.background,
                  borderRadius:
                      BorderRadius.circular(30),
                ),

                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      // ==========================================
                      // HEADER
                      // ==========================================

                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration:
                                BoxDecoration(
                              color:
                                  DefaultAppColors
                                      .peach,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                18,
                              ),
                            ),
                            child: const Icon(
                              Icons
                                  .photo_library_outlined,
                              color:
                                  DefaultAppColors
                                      .terracotta,
                              size: 27,
                            ),
                          ),

                          const SizedBox(width: 15),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                              children: [
                                Text(
                                  'Add memories',
                                  style: AppTextStyles
                                      .title
                                      .copyWith(
                                    fontSize: 27,
                                  ),
                                ),

                                const SizedBox(
                                  height: 2,
                                ),

                                Text(
                                  'Save a moment from your adventure',
                                  style: AppTextStyles
                                      .body
                                      .copyWith(
                                    fontSize: 13,
                                    color:
                                        DefaultAppColors
                                            .textDark
                                            .withValues(
                                      alpha: 0.60,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          IconButton(
                            onPressed:
                                isUploading
                                    ? null
                                    : () {
                                        Navigator.pop(
                                          context,
                                        );
                                      },
                            icon: const Icon(
                              Icons.close,
                              color:
                                  DefaultAppColors
                                      .textDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // ==========================================
                      // TITLE
                      // ==========================================

                      Text(
                        'Memory title',
                        style: AppTextStyles.body
                            .copyWith(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Container(
                        decoration:
                            BoxDecoration(
                          color:
                              DefaultAppColors.white,
                          borderRadius:
                              BorderRadius.circular(
                            18,
                          ),
                        ),
                        child: TextField(
                          controller:
                              titleController,
                          enabled:
                              !isUploading,
                          textCapitalization:
                              TextCapitalization
                                  .sentences,
                          style: AppTextStyles
                              .body
                              .copyWith(
                            fontSize: 16,
                          ),
                          decoration:
                              InputDecoration(
                            hintText:
                                'e.g. First day in Rome ❤️',
                            hintStyle:
                                AppTextStyles
                                    .body
                                    .copyWith(
                              fontSize: 16,
                              color:
                                  DefaultAppColors
                                      .textDark
                                      .withValues(
                                alpha: 0.40,
                              ),
                            ),
                            border:
                                InputBorder.none,
                            contentPadding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 18,
                              vertical: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // ==========================================
                      // PHOTOS
                      // ==========================================

                      Row(
                        children: [
                          Text(
                            'Photos',
                            style: AppTextStyles
                                .body
                                .copyWith(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),

                          const Spacer(),

                          if (selectedImages
                              .isNotEmpty)
                            Text(
                              '${selectedImages.length} '
                              '${selectedImages.length == 1 ? 'photo' : 'photos'}',
                              style: AppTextStyles
                                  .body
                                  .copyWith(
                                fontSize: 13,
                                color:
                                    DefaultAppColors
                                        .textDark
                                        .withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // ==========================================
                      // SELECT PHOTOS
                      // ==========================================

                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : pickImages,
                        child: Container(
                          width: double.infinity,
                          height:
                              selectedImages
                                      .isEmpty
                                  ? 130
                                  : 58,
                          decoration:
                              BoxDecoration(
                            color:
                                DefaultAppColors
                                    .peach,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child:
                              selectedImages
                                      .isEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        const Icon(
                                          Icons
                                              .add_photo_alternate_outlined,
                                          size: 30,
                                          color:
                                              DefaultAppColors
                                                  .terracotta,
                                        ),
                                        const SizedBox(
                                          height: 7,
                                        ),
                                        Text(
                                          'Choose photos',
                                          style: AppTextStyles
                                              .body
                                              .copyWith(
                                            fontSize:
                                                16,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                DefaultAppColors
                                                    .terracotta,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        const Icon(
                                          Icons
                                              .add_photo_alternate_outlined,
                                          size: 23,
                                          color:
                                              DefaultAppColors
                                                  .terracotta,
                                        ),
                                        const SizedBox(
                                          width: 8,
                                        ),
                                        Text(
                                          'Add more photos',
                                          style: AppTextStyles
                                              .body
                                              .copyWith(
                                            fontSize:
                                                15,
                                            fontWeight:
                                                FontWeight
                                                    .w600,
                                            color:
                                                DefaultAppColors
                                                    .terracotta,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),

                      // ==========================================
                      // PHOTO GRID
                      // ==========================================

                      if (selectedImages
                          .isNotEmpty) ...[
                        const SizedBox(height: 14),

                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              selectedImages
                                  .length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          itemBuilder:
                              (context, index) {
                            return Stack(
                              children: [
                                Positioned.fill(
                                  child:
                                      ClipRRect(
                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      14,
                                    ),
                                    child:
                                        Image.file(
                                      selectedImages[
                                          index],
                                      fit: BoxFit
                                          .cover,
                                    ),
                                  ),
                                ),

                                Positioned(
                                  top: 5,
                                  right: 5,
                                  child:
                                      GestureDetector(
                                    onTap:
                                        isUploading
                                            ? null
                                            : () {
                                                removeImage(
                                                  index,
                                                );
                                              },
                                    child:
                                        Container(
                                      width: 27,
                                      height: 27,
                                      decoration:
                                          BoxDecoration(
                                        color: Colors
                                            .black
                                            .withValues(
                                          alpha:
                                              0.65,
                                        ),
                                        shape:
                                            BoxShape
                                                .circle,
                                      ),
                                      child:
                                          const Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors
                                            .white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 25),

                      // ==========================================
                      // SAVE
                      // ==========================================

                      SizedBox(
                        width:
                            double.infinity,
                        height: 54,
                        child:
                            ElevatedButton(
                          onPressed:
                              isUploading
                                  ? null
                                  : saveMemory,
                          style:
                              ElevatedButton
                                  .styleFrom(
                            backgroundColor:
                                DefaultAppColors
                                    .terracotta,
                            disabledBackgroundColor:
                                DefaultAppColors
                                    .terracotta
                                    .withValues(
                              alpha: 0.5,
                            ),
                            foregroundColor:
                                DefaultAppColors
                                    .white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                28,
                              ),
                            ),
                          ),
                          child: isUploading
                              ? const SizedBox(
                                  width: 23,
                                  height: 23,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2.5,
                                    color:
                                        DefaultAppColors
                                            .white,
                                  ),
                                )
                              : Text(
                                  'Save memory',
                                  style:
                                      AppTextStyles
                                          .button
                                          .copyWith(
                                    color:
                                        DefaultAppColors
                                            .white,
                                    fontSize: 18,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      titleController.dispose();
    });
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          DefaultAppColors.background,

      body: SafeArea(
        child: Padding(
          padding:
              const EdgeInsets.symmetric(
            horizontal: 28,
          ),

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
                          DefaultAppColors
                              .terracotta,
                      size: 21,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),

                  const Spacer(),

                  Text(
                    'EVARA',
                    style:
                        AppTextStyles.title
                            .copyWith(
                      fontSize: 22,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // ==========================================
              // HEADER
              // ==========================================

              Text(
                'Memories',
                style:
                    AppTextStyles.title.copyWith(
                  fontSize: 38,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 6),

              Text(
                widget.adventureName,
                style:
                    AppTextStyles.body.copyWith(
                  fontSize: 18,
                  color: DefaultAppColors
                      .textDark
                      .withValues(
                    alpha: 0.60,
                  ),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 25),

              // ==========================================
              // MEMORIES + ADD BUTTON
              // ==========================================

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed:
                      _showAddMemoryDialog,
                  icon: const Icon(
                    Icons.add,
                    size: 20,
                  ),
                  label: const Text(
                    'Add memory',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        DefaultAppColors
                            .terracotta,
                    foregroundColor:
                        DefaultAppColors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==========================================
              // MEMORY LIST
              // ==========================================

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String,
                            dynamic>>>(
                  stream: _firestore
                      .collection('adventures')
                      .doc(widget.adventureId)
                      .collection('memories')
                      .orderBy(
                        'createdAt',
                        descending: true,
                      )
                      .snapshots(),

                  builder:
                      (context, snapshot) {
                    if (snapshot
                            .connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(
                          color:
                              DefaultAppColors
                                  .terracotta,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load memories.',
                          style: AppTextStyles
                              .body
                              .copyWith(
                            fontSize: 16,
                          ),
                        ),
                      );
                    }

                    final memories =
                        snapshot.data?.docs ??
                            [];

                    if (memories.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.separated(
                      physics:
                          const BouncingScrollPhysics(),
                      itemCount:
                          memories.length,
                      separatorBuilder:
                          (context, index) =>
                              const SizedBox(
                        height: 16,
                      ),
                      itemBuilder:
                          (context, index) {
                        final data =
                            memories[index]
                                .data();

                        return _MemoryCard(
                          title:
                              data['title'] ??
                                  'Memory',
                          imageUrls:
                              List<String>.from(
                            data['imageUrls'] ??
                                [],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // EMPTY STATE
  // ==========================================

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment:
            MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color:
                  DefaultAppColors.peach,
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              size: 42,
              color:
                  DefaultAppColors.terracotta,
            ),
          ),

          const SizedBox(height: 24),

          Text(
            'No memories yet',
            style:
                AppTextStyles.title.copyWith(
              fontSize: 27,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 10),

          Text(
            'Save the moments that make\n'
            'your adventure special.',
            style:
                AppTextStyles.body.copyWith(
              fontSize: 16,
              color: DefaultAppColors
                  .textDark
                  .withValues(
                alpha: 0.62,
              ),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ======================================================
// MEMORY CARD
// ======================================================

class _MemoryCard extends StatelessWidget {
  final String title;
  final List<String> imageUrls;

  const _MemoryCard({
    required this.title,
    required this.imageUrls,
  });

  @override
  Widget build(BuildContext context) {
    final String? coverImage =
        imageUrls.isNotEmpty
            ? imageUrls.first
            : null;

    return Container(
      width: double.infinity,

      decoration: BoxDecoration(
        color: DefaultAppColors.white,
        borderRadius:
            BorderRadius.circular(24),
      ),

      clipBehavior: Clip.antiAlias,

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          // ==========================================
          // COVER
          // ==========================================

          if (coverImage != null)
            SizedBox(
              width: double.infinity,
              height: 190,
              child: Image.network(
                coverImage,
                fit: BoxFit.cover,
                errorBuilder:
                    (context, error, stackTrace) {
                  return Container(
                    color:
                        DefaultAppColors.peach,
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
            )
          else
            Container(
              width: double.infinity,
              height: 190,
              color:
                  DefaultAppColors.peach,
              child: const Icon(
                Icons.photo_outlined,
                size: 45,
                color:
                    DefaultAppColors
                        .terracotta,
              ),
            ),

          // ==========================================
          // INFO
          // ==========================================

          Padding(
            padding:
                const EdgeInsets.all(18),

            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles
                        .body
                        .copyWith(
                      fontSize: 20,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),

                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 11,
                    vertical: 6,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        DefaultAppColors
                            .peach,
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                  child: Text(
                    '${imageUrls.length} '
                    '${imageUrls.length == 1 ? 'photo' : 'photos'}',
                    style: AppTextStyles
                        .body
                        .copyWith(
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
          ),
        ],
      ),
    );
  }
}