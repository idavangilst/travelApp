import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

class AppTextStyles {
  static TextStyle get title => GoogleFonts.cormorantGaramond(
        fontSize: 52,
        fontWeight: FontWeight.w400,
        color: DefaultAppColors.terracotta,
        letterSpacing: 3,
      );

  static TextStyle get button => GoogleFonts.cormorantGaramond(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: DefaultAppColors.terracotta,
      );

  static TextStyle get body => GoogleFonts.cormorantGaramond(
        fontSize: 18,
        color: DefaultAppColors.textDark,
      );
}