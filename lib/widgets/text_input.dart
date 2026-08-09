import 'package:flutter/material.dart';

import '../theme/colors.dart';

class EvaraTextField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;

  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const EvaraTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
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
          keyboardType: keyboardType,
          obscureText: obscureText,

          style: const TextStyle(
            fontSize: 17,
            color: DefaultAppColors.textDark,
          ),

          decoration: InputDecoration(
            hintText: hint,

            hintStyle: TextStyle(
              color: DefaultAppColors.textDark.withValues(alpha: 0.45),
            ),

            filled: true,
            fillColor: DefaultAppColors.white,

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 18,
            ),

            suffixIcon: suffixIcon,

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: const BorderSide(
                color: DefaultAppColors.terracotta,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}