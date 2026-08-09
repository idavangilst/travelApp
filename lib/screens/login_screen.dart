import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import '../widgets/text_input.dart';
import 'adventure_hub_screen.dart';
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
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Please enter your email and password.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdventureHubScreen(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message;

      switch (e.code) {
        case 'invalid-credential':
          message = 'Incorrect email or password.';
          break;

        case 'user-not-found':
          message = 'No account found with this email.';
          break;

        case 'wrong-password':
          message = 'Incorrect password.';
          break;

        case 'invalid-email':
          message = 'Please enter a valid email address.';
          break;

        case 'too-many-requests':
          message = 'Too many attempts. Please try again later.';
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
      SnackBar(
        content: Text(message),
      ),
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
              const SizedBox(height: 55),

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

              const SizedBox(height: 15),

              Text(
                'EVARA',
                style: AppTextStyles.title.copyWith(
                  fontSize: 42,
                ),
              ),

              const SizedBox(height: 25),

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
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 45),

              EvaraTextField(
                label: 'Email',
                hint: 'you@example.com',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 22),

              EvaraTextField(
                label: 'Password',
                hint: 'Your password',
                controller: _passwordController,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: DefaultAppColors.terracotta,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // We'll build password reset later.
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

              const SizedBox(height: 20),

              _isLoading
                  ? const CircularProgressIndicator(
                      color: DefaultAppColors.terracotta,
                    )
                  : PrimaryButton(
                      text: 'Login',
                      onPressed: _login,
                    ),

              const SizedBox(height: 30),

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
                        color: DefaultAppColors.textDark.withValues(
                          alpha: 0.6,
                        ),
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

              const SizedBox(height: 20),

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
                    style: const TextStyle(
                      color: DefaultAppColors.textDark,
                      fontSize: 15,
                    ),
                    children: [
                      const TextSpan(
                        text: "Don't have an account? ",
                      ),
                      TextSpan(
                        text: 'Sign up',
                        style: const TextStyle(
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