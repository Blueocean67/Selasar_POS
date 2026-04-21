import 'package:flutter/material.dart';

class CustomInput extends StatelessWidget {
  final String hint;
  final bool isPassword;
  final TextInputType keyboardType;
  final IconData? icon;

  const CustomInput({
    super.key, // Pakai super.key (fitur Flutter terbaru lebih simpel)
    required this.hint,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      obscureText: isPassword,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        // Tambahkan padding di prefixIcon agar icon tidak terlalu nempel ke pinggir
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: Colors.grey[200],
        // Pakai padding horizontal agar teks input tidak mepet ke kiri/kanan
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}