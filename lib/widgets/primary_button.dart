
import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/text_styles.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      height: 56,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: DefaultAppColors.white,
          foregroundColor: DefaultAppColors.terracotta,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          text,
          style: AppTextStyles.button.copyWith(
            fontSize: 21,
          ),
        ),
      ),
    );
  }
}
