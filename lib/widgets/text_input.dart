import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

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
        // ==========================================
        // LABEL
        // ==========================================

        Text(
          label,
          style: AppTextStyles.body.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 7),

        // ==========================================
        // TEXT FIELD
        // ==========================================

        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,

          style: AppTextStyles.body.copyWith(
            fontSize: 17,
            color: DefaultAppColors.textDark,
          ),

          cursorColor:
              DefaultAppColors.terracotta,

          decoration: InputDecoration(
            hintText: hint,

            hintStyle:
                AppTextStyles.body.copyWith(
              fontSize: 17,
              color: DefaultAppColors.textDark
                  .withValues(alpha: 0.42),
            ),

            filled: true,
            fillColor: DefaultAppColors.white,

            // Gør feltet mindre og mere elegant
            contentPadding:
                const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 14,
            ),

            suffixIcon: suffixIcon,

            // ==========================================
            // BORDER
            // ==========================================

            border: OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            enabledBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: BorderSide.none,
            ),

            focusedBorder:
                OutlineInputBorder(
              borderRadius:
                  BorderRadius.circular(18),
              borderSide: const BorderSide(
                color:
                    DefaultAppColors.terracotta,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
