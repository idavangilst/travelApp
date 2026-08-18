import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:saver_gallery/saver_gallery.dart';

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
  State<MemoriesScreen> createState() => _MemoriesScreenState();
}

class _MemoriesScreenState extends State<MemoriesScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  bool _isDownloadingAll = false;

  // ==========================================
  // ADD MEMORY POPUP
  // ==========================================

  void _showAddMemoryDialog() {
    final TextEditingController titleController =
        TextEditingController();

    final ImagePicker imagePicker = ImagePicker();

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
                  for (final image in pickedImages) {
                    final File file = File(image.path);

                    final bool alreadyAdded =
                        selectedImages.any(
                      (existingImage) =>
                          existingImage.path == file.path,
                    );

                    if (!alreadyAdded) {
                      selectedImages.add(file);
                    }
                  }
                });
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(context).showSnackBar(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please give your memory a title.',
                    ),
                  ),
                );

                return;
              }

              if (selectedImages.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
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

                final DocumentReference memoryReference =
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
                          .child('adventure_memories')
                          .child(widget.adventureId)
                          .child(memoryReference.id)
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
                      await storageReference.getDownloadURL();

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

                ScaffoldMessenger.of(context).showSnackBar(
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

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Something went wrong: $e',
                    ),
                  ),
                );
              }
            }

            return Dialog(
              backgroundColor: Colors.transparent,
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
                      // HEADER
                      Row(
                        children: [
                          Container(
                            width: 54,
                            height: 54,
                            decoration:
                                BoxDecoration(
                              color:
                                  DefaultAppColors.peach,
                              borderRadius:
                                  BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.photo_library_outlined,
                              color:
                                  DefaultAppColors.terracotta,
                              size: 27,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add memories',
                                  style:
                                      AppTextStyles.title.copyWith(
                                    fontSize: 27,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Save a moment from your adventure',
                                  style:
                                      AppTextStyles.body.copyWith(
                                    fontSize: 13,
                                    color:
                                        DefaultAppColors.textDark.withValues(
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
                                  DefaultAppColors.textDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 25),

                      // TITLE
                      Text(
                        'Memory title',
                        style:
                            AppTextStyles.body.copyWith(
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
                              BorderRadius.circular(18),
                        ),
                        child: TextField(
                          controller:
                              titleController,
                          enabled:
                              !isUploading,
                          textCapitalization:
                              TextCapitalization.sentences,
                          style:
                              AppTextStyles.body.copyWith(
                            fontSize: 16,
                          ),
                          decoration:
                              InputDecoration(
                            hintText:
                                'e.g. First day in Rome ❤️',
                            hintStyle:
                                AppTextStyles.body.copyWith(
                              fontSize: 16,
                              color:
                                  DefaultAppColors.textDark.withValues(
                                alpha: 0.40,
                              ),
                            ),
                            border:
                                InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 17,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      // PHOTOS HEADER
                      Row(
                        children: [
                          Text(
                            'Photos',
                            style:
                                AppTextStyles.body.copyWith(
                              fontSize: 15,
                              fontWeight:
                                  FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (selectedImages.isNotEmpty)
                            Text(
                              '${selectedImages.length} '
                              '${selectedImages.length == 1 ? 'photo' : 'photos'}',
                              style:
                                  AppTextStyles.body.copyWith(
                                fontSize: 13,
                                color:
                                    DefaultAppColors.textDark.withValues(
                                  alpha: 0.55,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 9),

                      // SELECT PHOTOS
                      GestureDetector(
                        onTap:
                            isUploading
                                ? null
                                : pickImages,
                        child: Container(
                          width:
                              double.infinity,
                          height:
                              selectedImages.isEmpty
                                  ? 130
                                  : 58,
                          decoration:
                              BoxDecoration(
                            color:
                                DefaultAppColors.peach,
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child:
                              selectedImages.isEmpty
                                  ? Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons
                                              .add_photo_alternate_outlined,
                                          size: 30,
                                          color:
                                              DefaultAppColors.terracotta,
                                        ),
                                        const SizedBox(
                                            height: 7),
                                        Text(
                                          'Choose photos',
                                          style:
                                              AppTextStyles.body.copyWith(
                                            fontSize: 16,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                DefaultAppColors.terracotta,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons
                                              .add_photo_alternate_outlined,
                                          size: 23,
                                          color:
                                              DefaultAppColors.terracotta,
                                        ),
                                        const SizedBox(
                                            width: 8),
                                        Text(
                                          'Add more photos',
                                          style:
                                              AppTextStyles.body.copyWith(
                                            fontSize: 15,
                                            fontWeight:
                                                FontWeight.w600,
                                            color:
                                                DefaultAppColors.terracotta,
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),

                      // PHOTO GRID
                      if (selectedImages.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        GridView.builder(
                          shrinkWrap: true,
                          physics:
                              const NeverScrollableScrollPhysics(),
                          itemCount:
                              selectedImages.length,
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
                                  child: ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(14),
                                    child:
                                        Image.file(
                                      selectedImages[index],
                                      fit: BoxFit.cover,
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
                                    child: Container(
                                      width: 27,
                                      height: 27,
                                      decoration:
                                          BoxDecoration(
                                        color:
                                            Colors.black.withValues(
                                          alpha: 0.65,
                                        ),
                                        shape:
                                            BoxShape.circle,
                                      ),
                                      child:
                                          const Icon(
                                        Icons.close,
                                        size: 16,
                                        color:
                                            Colors.white,
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

                      // SAVE
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
                              ElevatedButton.styleFrom(
                            backgroundColor:
                                DefaultAppColors.terracotta,
                            disabledBackgroundColor:
                                DefaultAppColors.terracotta.withValues(
                              alpha: 0.5,
                            ),
                            foregroundColor:
                                DefaultAppColors.white,
                            elevation: 0,
                            shape:
                                RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(28),
                            ),
                          ),
                          child:
                              isUploading
                                  ? const SizedBox(
                                      width: 23,
                                      height: 23,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color:
                                            DefaultAppColors.white,
                                      ),
                                    )
                                  : Text(
                                      'Save memory',
                                      style:
                                          AppTextStyles.button.copyWith(
                                        color:
                                            DefaultAppColors.white,
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
  // OPEN MEMORY
  // ==========================================

  void _showMemoryDetails(
    String title,
    List<String> imageUrls,
  ) {
    if (imageUrls.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoryDetailsScreen(
          title: title,
          imageUrls: imageUrls,
        ),
      ),
    );
  }

  // ==========================================
  // DOWNLOAD ONE IMAGE
  // ==========================================

  Future<void> _downloadImage(
    String imageUrl,
    String fileName,
  ) async {
    try {
      final response =
          await http.get(Uri.parse(imageUrl));

      if (response.statusCode != 200) {
        throw Exception(
          'Could not download image.',
        );
      }

      final Uint8List bytes =
          response.bodyBytes;

      final result =
          await SaverGallery.saveImage(
        bytes,
        quality: 100,
        fileName: fileName,
        skipIfExists: false,
        albumPath: 'EVARA',
      );

      debugPrint(
        'IMAGE SAVED: ${result.savedUri}',
      );
    } catch (e) {
      debugPrint(
        'DOWNLOAD IMAGE ERROR: $e',
      );

      rethrow;
    }
  }

  // ==========================================
  // DOWNLOAD MEMORY
  // ==========================================

  Future<void> _downloadMemory(
    String title,
    List<String> imageUrls,
  ) async {
    if (imageUrls.isEmpty) {
      return;
    }

    try {
      for (int i = 0;
          i < imageUrls.length;
          i++) {
        await _downloadImage(
          imageUrls[i],
          'EVARA_${_safeFileName(title)}_$i.jpg',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${imageUrls.length} '
            '${imageUrls.length == 1 ? 'photo' : 'photos'} '
            'saved to your gallery ❤️',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not download the photos.',
          ),
        ),
      );
    }
  }

  // ==========================================
  // DOWNLOAD ALL PHOTOS
  // ==========================================

  Future<void> _downloadAllPhotos() async {
    if (_isDownloadingAll) {
      return;
    }

    setState(() {
      _isDownloadingAll = true;
    });

    try {
      final QuerySnapshot<
          Map<String, dynamic>> snapshot =
          await _firestore
              .collection('adventures')
              .doc(widget.adventureId)
              .collection('memories')
              .get();

      int totalPhotos = 0;

      for (final document in snapshot.docs) {
        final data = document.data();

        final List<String> imageUrls =
            List<String>.from(
          data['imageUrls'] ?? [],
        );

        totalPhotos += imageUrls.length;
      }

      if (totalPhotos == 0) {
        if (!mounted) return;

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'There are no photos to download yet.',
            ),
          ),
        );

        return;
      }

      int downloadedPhotos = 0;

      for (final document in snapshot.docs) {
        final data = document.data();

        final String title =
            data['title'] ?? 'Memory';

        final List<String> imageUrls =
            List<String>.from(
          data['imageUrls'] ?? [],
        );

        for (int i = 0;
            i < imageUrls.length;
            i++) {
          downloadedPhotos++;

          if (mounted) {
            setState(() {});
          }

          await _downloadImage(
            imageUrls[i],
            'EVARA_${_safeFileName(title)}_$i.jpg',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '$downloadedPhotos '
            '${downloadedPhotos == 1 ? 'photo' : 'photos'} '
            'saved to your gallery ❤️',
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'DOWNLOAD ALL ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not download all photos.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloadingAll = false;
        });
      }
    }
  }

  // ==========================================
  // SAFE FILE NAME
  // ==========================================

  String _safeFileName(String value) {
    return value
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '_',
        );
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          DefaultAppColors.background,
          floatingActionButton: FloatingActionButton.extended(
          onPressed: _showAddMemoryDialog,
          backgroundColor: DefaultAppColors.terracotta,
          elevation: 4,
          icon: const Icon(
            Icons.add_photo_alternate_outlined,
            color: DefaultAppColors.white,
          ),
          label: Text(
            'Add memory',
            style: AppTextStyles.button.copyWith(
              color: DefaultAppColors.white,
              fontSize: 15,
            ),
          ),
        ),
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
                    style:
                        AppTextStyles.title.copyWith(
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
                  color:
                      DefaultAppColors.textDark
                          .withValues(alpha: 0.60),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // ==========================================
              // DOWNLOAD ALL
              // ==========================================

              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton.icon(
                  onPressed:
                      _isDownloadingAll
                          ? null
                          : _downloadAllPhotos,
                  icon:
                      _isDownloadingAll
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    DefaultAppColors.white,
                              ),
                            )
                          : const Icon(
                              Icons.download_outlined,
                              size: 20,
                            ),
                  label: Text(
                    _isDownloadingAll
                        ? 'Downloading...'
                        : 'Download all',
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        DefaultAppColors.terracotta,
                    disabledBackgroundColor:
                        DefaultAppColors.terracotta
                            .withValues(alpha: 0.5),
                    foregroundColor:
                        DefaultAppColors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(24),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ==========================================
              // MEMORY LIST
              // ==========================================

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
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
                              DefaultAppColors.terracotta,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Could not load memories.',
                          style:
                              AppTextStyles.body.copyWith(
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

                        final List<String>
                            imageUrls =
                            List<String>.from(
                          data['imageUrls'] ??
                              [],
                        );

                        final String title =
                            data['title'] ??
                                'Memory';

                        return _MemoryCard(
                          title: title,
                          imageUrls:
                              imageUrls,
                          onTap: () {
                            _showMemoryDetails(
                              title,
                              imageUrls,
                            );
                          },
                          onDownload: () {
                            _downloadMemory(
                              title,
                              imageUrls,
                            );
                          },
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
            decoration:
                BoxDecoration(
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
              color:
                  DefaultAppColors.textDark
                      .withValues(alpha: 0.62),
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
  final VoidCallback onTap;
  final VoidCallback onDownload;

  const _MemoryCard({
    required this.title,
    required this.imageUrls,
    required this.onTap,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final String? coverImage =
        imageUrls.isNotEmpty
            ? imageUrls.first
            : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration:
            BoxDecoration(
          color:
              DefaultAppColors.white,
          borderRadius:
              BorderRadius.circular(24),
        ),
        clipBehavior:
            Clip.antiAlias,
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // ==========================================
            // COVER
            // ==========================================

            Stack(
              children: [
                if (coverImage != null)
                  SizedBox(
                    width:
                        double.infinity,
                    height: 190,
                    child:
                        Image.network(
                      coverImage,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          color:
                              DefaultAppColors.peach,
                          child:
                              const Icon(
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
                    width:
                        double.infinity,
                    height: 190,
                    color:
                        DefaultAppColors.peach,
                    child:
                        const Icon(
                      Icons.photo_outlined,
                      size: 45,
                      color:
                          DefaultAppColors
                              .terracotta,
                    ),
                  ),

                // DOWNLOAD BUTTON
                Positioned(
                  top: 12,
                  right: 12,
                  child: GestureDetector(
                    onTap:
                        imageUrls.isEmpty
                            ? null
                            : onDownload,
                    child: Container(
                      width: 43,
                      height: 43,
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black.withValues(
                          alpha: 0.55,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.download_outlined,
                        color:
                            Colors.white,
                        size: 21,
                      ),
                    ),
                  ),
                ),
              ],
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
                      style:
                          AppTextStyles.body.copyWith(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 6,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          DefaultAppColors.peach,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: Text(
                      '${imageUrls.length} '
                      '${imageUrls.length == 1 ? 'photo' : 'photos'}',
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

                  const SizedBox(width: 8),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color:
                        DefaultAppColors
                            .terracotta,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================
// MEMORY DETAILS SCREEN
// ======================================================

class MemoryDetailsScreen
    extends StatefulWidget {
  final String title;
  final List<String> imageUrls;

  const MemoryDetailsScreen({
    super.key,
    required this.title,
    required this.imageUrls,
  });

  @override
  State<MemoryDetailsScreen> createState() =>
      _MemoryDetailsScreenState();
}

class _MemoryDetailsScreenState
    extends State<MemoryDetailsScreen> {
  final PageController _pageController =
      PageController();

  int _currentIndex = 0;
  bool _isDownloading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ==========================================
  // DOWNLOAD CURRENT MEMORY
  // ==========================================

  Future<void> _downloadPhotos() async {
    if (_isDownloading) {
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      for (int i = 0;
          i < widget.imageUrls.length;
          i++) {
        final response =
            await http.get(
          Uri.parse(
            widget.imageUrls[i],
          ),
        );

        if (response.statusCode != 200) {
          throw Exception(
            'Could not download image.',
          );
        }

        await SaverGallery.saveImage(
          response.bodyBytes,
          quality: 100,
          fileName:
              'EVARA_${_safeFileName(widget.title)}_$i.jpg',
          skipIfExists: false,
          albumPath: 'EVARA',
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            '${widget.imageUrls.length} '
            '${widget.imageUrls.length == 1 ? 'photo' : 'photos'} '
            'saved to your gallery ❤️',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Could not download the photos.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  String _safeFileName(String value) {
    return value
        .replaceAll(
          RegExp(r'[^\w\s-]'),
          '',
        )
        .replaceAll(
          RegExp(r'\s+'),
          '_',
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black,

      body: SafeArea(
        child: Stack(
          children: [
            // ==========================================
            // PHOTOS
            // ==========================================

            PageView.builder(
              controller:
                  _pageController,
              itemCount:
                  widget.imageUrls.length,
              onPageChanged:
                  (index) {
                setState(() {
                  _currentIndex =
                      index;
                });
              },
              itemBuilder:
                  (context, index) {
                return InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 4.0,
                  child: Center(
                    child:
                        Image.network(
                      widget.imageUrls[index],
                      fit: BoxFit.contain,
                      loadingBuilder:
                          (
                        context,
                        child,
                        loadingProgress,
                      ) {
                        if (loadingProgress ==
                            null) {
                          return child;
                        }

                        return const Center(
                          child:
                              CircularProgressIndicator(
                            color:
                                Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            // ==========================================
            // TOP BAR
            // ==========================================

            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: Row(
                children: [
                  Container(
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black.withValues(
                        alpha: 0.45,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        IconButton(
                      icon:
                          const Icon(
                        Icons
                            .arrow_back_ios_new,
                        color:
                            Colors.white,
                        size: 20,
                      ),
                      onPressed: () {
                        Navigator.pop(
                          context,
                        );
                      },
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration:
                          BoxDecoration(
                        color:
                            Colors.black.withValues(
                          alpha: 0.45,
                        ),
                        borderRadius:
                            BorderRadius.circular(
                          22,
                        ),
                      ),
                      child: Text(
                        widget.title,
                        style:
                            AppTextStyles.body.copyWith(
                          color:
                              Colors.white,
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow:
                            TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Container(
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black.withValues(
                        alpha: 0.45,
                      ),
                      shape:
                          BoxShape.circle,
                    ),
                    child:
                        IconButton(
                      icon:
                          _isDownloading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child:
                                      CircularProgressIndicator(
                                    strokeWidth:
                                        2,
                                    color:
                                        Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons
                                      .download_outlined,
                                  color:
                                      Colors.white,
                                  size: 22,
                                ),
                      onPressed:
                          _isDownloading
                              ? null
                              : _downloadPhotos,
                    ),
                  ),
                ],
              ),
            ),

            // ==========================================
            // IMAGE COUNTER
            // ==========================================

            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 15,
                      vertical: 7,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          Colors.black.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                        20,
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} / '
                      '${widget.imageUrls.length}',
                      style:
                          AppTextStyles.body.copyWith(
                        color:
                            Colors.white,
                        fontSize: 14,
                        fontWeight:
                            FontWeight.w600,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DOTS
                  if (widget.imageUrls.length <=
                      15)
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children:
                          List.generate(
                        widget.imageUrls.length,
                        (index) {
                          return AnimatedContainer(
                            duration:
                                const Duration(
                              milliseconds: 200,
                            ),
                            margin:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 3,
                            ),
                            width:
                                index ==
                                        _currentIndex
                                    ? 18
                                    : 6,
                            height: 6,
                            decoration:
                                BoxDecoration(
                              color:
                                  Colors.white.withValues(
                                alpha:
                                    index ==
                                            _currentIndex
                                        ? 1
                                        : 0.45,
                              ),
                              borderRadius:
                                  BorderRadius.circular(
                                10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}