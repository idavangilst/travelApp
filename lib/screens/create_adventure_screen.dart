import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/adventure.dart';
import '../services/adventure_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';
import 'adventure_screen.dart';

class CreateAdventureScreen extends StatefulWidget {
  const CreateAdventureScreen({super.key});

  @override
  State<CreateAdventureScreen> createState() =>
      _CreateAdventureScreenState();
}

class _CreateAdventureScreenState
    extends State<CreateAdventureScreen> {
  final AdventureService _adventureService =
      AdventureService();

  final TextEditingController _adventureNameController =
      TextEditingController();

  final TextEditingController _destinationController =
      TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;

  File? _coverImage;

  bool _isLoading = false;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _adventureNameController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  // ==========================================
  // PICK COVER IMAGE
  // ==========================================

  Future<void> _pickCoverImage() async {
    try {
      final XFile? pickedImage =
          await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (pickedImage == null) return;

      setState(() {
        _coverImage = File(pickedImage.path);
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while selecting the image.',
          ),
        ),
      );
    }
  }

  // ==========================================
  // START DATE
  // ==========================================

  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        if (_endDate != null &&
            _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  // ==========================================
  // END DATE
  // ==========================================

  Future<void> _selectEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please select a start date first.',
          ),
        ),
      );

      return;
    }

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate!,
      firstDate: _startDate!,
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  // ==========================================
  // UPLOAD COVER IMAGE
  // ==========================================

  Future<String?> _uploadCoverImage(
    String adventureId,
  ) async {
    if (_coverImage == null) {
      return null;
    }

    try {
      final FirebaseStorage storage =
          FirebaseStorage.instance;

      final Reference storageReference = storage
          .ref()
          .child('adventure_covers')
          .child('$adventureId.jpg');

      debugPrint(
        'Uploading image to: ${storageReference.fullPath}',
      );

      final UploadTask uploadTask =
          storageReference.putFile(
        _coverImage!,
        SettableMetadata(
          contentType: 'image/jpeg',
        ),
      );

      final TaskSnapshot snapshot =
          await uploadTask;

      debugPrint(
        'Upload complete: ${snapshot.state}',
      );

      final String imageUrl =
          await snapshot.ref.getDownloadURL();

      debugPrint(
        'Download URL: $imageUrl',
      );

      return imageUrl;
    } catch (e) {
      debugPrint(
        'COVER IMAGE UPLOAD ERROR: $e',
      );

      rethrow;
    }
  }

  // ==========================================
  // CREATE ADVENTURE
  // ==========================================

  Future<void> _createAdventure() async {
    final String adventureName =
        _adventureNameController.text.trim();

    final String destination =
        _destinationController.text.trim();

    if (adventureName.isEmpty ||
        destination.isEmpty ||
        _startDate == null ||
        _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill in all fields.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // ==========================================
      // CREATE ADVENTURE
      // ==========================================

      final Adventure adventure =
          await _adventureService.createAdventure(
        adventureName: adventureName,
        destination: destination,
        startDate: _startDate!,
        endDate: _endDate!,
      );

      // ==========================================
      // UPLOAD COVER IMAGE
      // ==========================================

      final String? imageUrl =
          await _uploadCoverImage(adventure.id);

      // ==========================================
      // SAVE IMAGE URL
      // ==========================================

      if (imageUrl != null) {
        await FirebaseFirestore.instance
            .collection('adventures')
            .doc(adventure.id)
            .update({
          'coverImageUrl': imageUrl,
        });
      }

      // ==========================================
      // GET UPDATED ADVENTURE
      // ==========================================

      final DocumentSnapshot<
          Map<String, dynamic>> updatedDocument =
          await FirebaseFirestore.instance
              .collection('adventures')
              .doc(adventure.id)
              .get();

      final Adventure updatedAdventure =
          Adventure.fromFirestore(updatedDocument);

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AdventureScreen(
            adventureId: updatedAdventure.id,
            adventureName: updatedAdventure.name,
            destination: updatedAdventure.destination,
            startDate: updatedAdventure.startDate,
            endDate: updatedAdventure.endDate,
            inviteCode: updatedAdventure.inviteCode,
            coverImageUrl: updatedAdventure.coverImageUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'CREATE ADVENTURE ERROR: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong while creating your adventure.',
          ),
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

  // ==========================================
  // DATE FORMAT
  // ==========================================

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          DefaultAppColors.background,

      appBar: AppBar(
        backgroundColor:
            DefaultAppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
          ),
          color:
              DefaultAppColors.terracotta,
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),

                // ==========================================
                // TITLE
                // ==========================================

                Text(
                  'Create your adventure',
                  style:
                      AppTextStyles.title.copyWith(
                    fontSize: 34,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  "Let's start planning your trip.",
                  style:
                      AppTextStyles.body.copyWith(
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 32),

                // ==========================================
                // COVER IMAGE
                // ==========================================

                Text(
                  'Cover photo',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap: _pickCoverImage,
                  child: Container(
                    width: double.infinity,
                    height: 190,
                    decoration: BoxDecoration(
                      color:
                          DefaultAppColors.peach,
                      borderRadius:
                          BorderRadius.circular(
                        24,
                      ),
                      image: _coverImage != null
                          ? DecorationImage(
                              image: FileImage(
                                _coverImage!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _coverImage == null
                        ? Column(
                            mainAxisAlignment:
                                MainAxisAlignment
                                    .center,
                            children: [
                              Container(
                                width: 58,
                                height: 58,
                                decoration:
                                    BoxDecoration(
                                  color:
                                      DefaultAppColors
                                          .white,
                                  shape:
                                      BoxShape.circle,
                                ),
                                child:
                                    const Icon(
                                  Icons
                                      .add_a_photo_outlined,
                                  size: 27,
                                  color:
                                      DefaultAppColors
                                          .terracotta,
                                ),
                              ),

                              const SizedBox(
                                height: 12,
                              ),

                              Text(
                                'Add a cover photo',
                                style: AppTextStyles
                                    .body
                                    .copyWith(
                                  fontSize: 17,
                                  fontWeight:
                                      FontWeight
                                          .w600,
                                  color:
                                      DefaultAppColors
                                          .terracotta,
                                ),
                              ),

                              const SizedBox(
                                height: 3,
                              ),

                              Text(
                                'Choose a photo from your library',
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
                          )
                        : Container(
                            decoration:
                                BoxDecoration(
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                24,
                              ),
                              color: Colors.black
                                  .withValues(
                                alpha: 0.20,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons
                                    .edit_outlined,
                                color:
                                    Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================
                // ADVENTURE NAME
                // ==========================================

                EvaraTextField(
                  label: 'Adventure name',
                  hint: 'e.g. Summer in Italy',
                  controller:
                      _adventureNameController,
                ),

                const SizedBox(height: 25),

                // ==========================================
                // DESTINATION
                // ==========================================

                EvaraTextField(
                  label: 'Destination',
                  hint: 'Where are you going?',
                  controller:
                      _destinationController,
                ),

                const SizedBox(height: 25),

                // ==========================================
                // START DATE
                // ==========================================

                Text(
                  'Start date',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        DefaultAppColors.textDark,
                  ),
                ),

                const SizedBox(height: 8),

                GestureDetector(
                  onTap:
                      _selectStartDate,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          DefaultAppColors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_today_outlined,
                          color:
                              DefaultAppColors
                                  .terracotta,
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Text(
                          _startDate == null
                              ? 'Select start date'
                              : _formatDate(
                                  _startDate!,
                                ),
                          style: TextStyle(
                            fontSize: 17,
                            color: _startDate ==
                                    null
                                ? DefaultAppColors
                                    .textDark
                                    .withValues(
                                    alpha: 0.45,
                                  )
                                : DefaultAppColors
                                    .textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // ==========================================
                // END DATE
                // ==========================================

                GestureDetector(
                  onTap:
                      _selectEndDate,
                  child: Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 20,
                      vertical: 18,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          DefaultAppColors.white,
                      borderRadius:
                          BorderRadius.circular(
                        18,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons
                              .calendar_today_outlined,
                          color:
                              DefaultAppColors
                                  .terracotta,
                        ),

                        const SizedBox(
                          width: 14,
                        ),

                        Text(
                          _endDate == null
                              ? 'Select end date'
                              : _formatDate(
                                  _endDate!,
                                ),
                          style: TextStyle(
                            fontSize: 17,
                            color: _endDate ==
                                    null
                                ? DefaultAppColors
                                    .textDark
                                    .withValues(
                                    alpha: 0.45,
                                  )
                                : DefaultAppColors
                                    .textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // ==========================================
                // CREATE BUTTON
                // ==========================================

                Center(
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color:
                              DefaultAppColors
                                  .terracotta,
                        )
                      : PrimaryButton(
                          text:
                              'Create Adventure',
                          onPressed:
                              _createAdventure,
                        ),
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