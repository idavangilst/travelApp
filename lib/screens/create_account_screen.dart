import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';

class CreateAccountScreen extends StatefulWidget {
  const CreateAccountScreen({super.key});

  @override
  State<CreateAccountScreen> createState() =>
      _CreateAccountScreenState();
}

class _CreateAccountScreenState
    extends State<CreateAccountScreen> {
  final TextEditingController _nameController =
      TextEditingController();

  final TextEditingController _emailController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ==========================================
  // CREATE ACCOUNT
  // ==========================================

  Future<void> _createAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // ------------------------------------------
    // VALIDATION
    // ------------------------------------------

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all fields.'),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password must be at least 6 characters.',
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
      // CREATE FIREBASE AUTH ACCOUNT
      // ==========================================

      final UserCredential userCredential =
          await FirebaseAuth.instance
              .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('User could not be created.');
      }

      // ==========================================
      // SAVE NAME TO FIREBASE AUTH PROFILE
      // ==========================================

      await user.updateDisplayName(name);

      // ==========================================
      // SAVE USER TO FIRESTORE
      // ==========================================

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
        'name': name,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // ==========================================
      // SUCCESS
      // ==========================================

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account created successfully!',
          ),
        ),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'email-already-in-use':
          message =
              'An account with this email already exists.';
          break;

        case 'invalid-email':
          message =
              'Please enter a valid email address.';
          break;

        case 'weak-password':
          message =
              'Please choose a stronger password.';
          break;

        default:
          message =
              'Something went wrong. Please try again.';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Something went wrong. Please try again.',
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
  // UI
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,

      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
            ),
            child: Column(
              children: [
                const SizedBox(height: 20),

                // ==========================================
                // BACK BUTTON
                // ==========================================

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: DefaultAppColors.terracotta,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),

                const SizedBox(height: 30),

                // ==========================================
                // EVARA
                // ==========================================

                Text(
                  'EVARA',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 32,
                  ),
                ),

                const SizedBox(height: 28),

                // ==========================================
                // HEADING
                // ==========================================

                Text(
                  'Create your account',
                  style: AppTextStyles.title.copyWith(
                    fontSize: 27,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 8),

                Text(
                  'Start creating your adventures.',
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 40),

                // ==========================================
                // NAME
                // ==========================================

                EvaraTextField(
                  label: 'Name',
                  hint: 'Your name',
                  controller: _nameController,
                ),

                const SizedBox(height: 22),

                // ==========================================
                // EMAIL
                // ==========================================

                EvaraTextField(
                  label: 'Email',
                  hint: 'you@example.com',
                  controller: _emailController,
                  keyboardType:
                      TextInputType.emailAddress,
                ),

                const SizedBox(height: 22),

                // ==========================================
                // PASSWORD
                // ==========================================

                EvaraTextField(
                  label: 'Password',
                  hint: 'At least 6 characters',
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color:
                          DefaultAppColors.terracotta,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword =
                            !_obscurePassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 34),

                // ==========================================
                // CREATE ACCOUNT BUTTON
                // ==========================================

                _isLoading
                    ? const CircularProgressIndicator(
                        color:
                            DefaultAppColors.terracotta,
                      )
                    : PrimaryButton(
                        text: 'Create account',
                        onPressed: _createAccount,
                      ),

                const SizedBox(height: 28),

                // ==========================================
                // LOGIN
                // ==========================================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style:
                          AppTextStyles.body.copyWith(
                        fontSize: 14,
                      ),
                    ),

                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Login',
                        style:
                            AppTextStyles.body.copyWith(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w600,
                          color: DefaultAppColors
                              .terracotta,
                        ),
                      ),
                    ),
                  ],
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

