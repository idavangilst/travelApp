import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import 'create_account_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      _showMessage('Welcome back ✨');
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        default:
          message = 'Something went wrong. Please try again.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const SizedBox(height: 70),

              Text(
                'EVARA',
                style: AppTextStyles.title.copyWith(
                  fontSize: 42,
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Welcome back',
                style: AppTextStyles.title.copyWith(
                  fontSize: 30,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'Continue your adventure.',
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 55),

              _EvaraTextField(
                controller: _emailController,
                label: 'Email',
                hint: 'Enter your email',
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

              _EvaraTextField(
                controller: _passwordController,
                label: 'Password',
                hint: 'Enter your password',
                obscureText: true,
              ),

              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // We add password reset later.
                  },
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      color: DefaultAppColors.terracotta,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              _isLoading
                  ? const CircularProgressIndicator(
                      color: DefaultAppColors.terracotta,
                    )
                  : PrimaryButton(
                      text: 'Login',
                      onPressed: _login,
                    ),

              const SizedBox(height: 35),

              Row(
                children: [
                  Expanded(
                    child: Divider(
                      color: DefaultAppColors.textDark.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Text(
                      'or',
                      style: TextStyle(
                        color: DefaultAppColors.textDark
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Divider(
                      color: DefaultAppColors.textDark.withValues(
                        alpha: 0.2,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CreateAccountScreen(),
                    ),
                  );
                },
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      color: DefaultAppColors.textDark,
                      fontSize: 15,
                    ),
                    children: [
                      const TextSpan(
                        text: "Don't have an account? ",
                      ),
                      TextSpan(
                        text: 'Sign up',
                        style: TextStyle(
                          color: DefaultAppColors.terracotta,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}

class _EvaraTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;

  const _EvaraTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: DefaultAppColors.textDark,
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: DefaultAppColors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),
          ),
        ),
      ],
    );
  }
}