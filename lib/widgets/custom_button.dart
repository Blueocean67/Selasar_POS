import 'package:flutter/material.dart';
// 1. Pastikan import ini mengarah ke file tempat class AppColors berada
import '../theme/app_colors.dart'; 

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color? color;
  final Color? textColor;
  final double height;

  const CustomButton({
    super.key, // Versi singkat dari Key? key
    required this.text,
    required this.onPressed,
    this.color,
    this.textColor,
    this.height = 50,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          // 2. Jika AppColors.primary masih merah, cek file app_colors.dart kamu
          backgroundColor: color ?? AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        onPressed: onPressed,
        child: Text(
          text,
          style: TextStyle(
            color: textColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}