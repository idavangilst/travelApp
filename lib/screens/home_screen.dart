import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';
import '../widgets/primary_button.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _titleMove;
  late Animation<double> _globeOpacity;
  late Animation<Offset> _globeSlide;
  late Animation<double> _buttonsOpacity;
  late Animation<Offset> _buttonsSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // --------------------------------
    // EVARA
    // --------------------------------

    _titleMove = Tween<double>(
      begin: 0.0,
      end: -0.72,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.35,
          0.70,
          curve: Curves.easeInOutCubic,
        ),
      ),
    );

    // --------------------------------
    // GLOBE
    // --------------------------------

    _globeOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.55,
          0.78,
          curve: Curves.easeIn,
        ),
      ),
    );

    _globeSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.55,
          0.80,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // --------------------------------
    // LOGIN BUTTON
    // --------------------------------

    _buttonsOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.72,
          1.0,
          curve: Curves.easeIn,
        ),
      ),
    );

    _buttonsSlide = Tween<Offset>(
      begin: const Offset(0, 0.10),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.72,
          1.0,
          curve: Curves.easeOutCubic,
        ),
      ),
    );

    // Start animation after a short pause
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) {
        _controller.forward();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DefaultAppColors.background,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Stack(
              children: [
                // ==========================================
                // EVARA
                // ==========================================

                Align(
                  alignment: Alignment(0, _titleMove.value),
                  child: Text(
                    'EVARA',
                    style: AppTextStyles.title,
                  ),
                ),

                // ==========================================
                // GLOBE
                // ==========================================

                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, -70),
                    child: FadeTransition(
                      opacity: _globeOpacity,
                      child: SlideTransition(
                        position: _globeSlide,
                        child: const Icon(
                          Icons.public,
                          size: 140,
                          color: DefaultAppColors.terracotta,
                        ),
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // LOGIN BUTTON
                // ==========================================

                Align(
                  alignment: Alignment.center,
                  child: Transform.translate(
                    offset: const Offset(0, 120),
                    child: FadeTransition(
                      opacity: _buttonsOpacity,
                      child: SlideTransition(
                        position: _buttonsSlide,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                          ),
                          child: PrimaryButton(
                            text:'Start your adventure',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}