import 'dart:ui';
import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF4A5D3F); // Hijau Hutan
  static const accent = Color(0xFFA3B18A);  // Hijau Sage
  static const bg = Color(0xFFF8F8F3);      // Krem sangat muda
  static const text = Color(0xFF2F312B);    // Gelap organik
  static const sub = Color(0xFF555B44);     // Hijau zaitun redup
}

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  State<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  bool isEnglish = false;

  String t(String id, String en) => isEnglish ? en : id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Stack(
        children: [
          /// 1. BACKGROUND IMAGE (Menggunakan Link Pexels Baru)
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                  'https://images.pexels.com/photos/11894196/pexels-photo-11894196.jpeg?auto=compress&cs=tinysrgb&w=1260&h=750&dpr=1',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          /// 2. OVERLAY BLUR & LIGHT TINT
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
            child: Container(
              color: Colors.white.withOpacity(0.1),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  /// 3. PREMIUM GLASSMORPHISM CARD
                  ClipRRect(
                    borderRadius: BorderRadius.circular(45),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(45),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.6),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: Column(
                          children: [
                            /// LOGO
                            Container(
                              height: 90,
                              width: 90,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Image.asset(
                                  'assets/images/SelasarLogo.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            /// JUDUL UTAMA
                            Text(
                              t("Selasar Ruang", "Selasar Ruang"),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                                letterSpacing: -1,
                              ),
                            ),
                            const SizedBox(height: 4),

                            /// SUBJUDUL
                            Text(
                              t("Akses Manajemen Kafe", "Cafe Management Access"),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.sub,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 16),

                            /// DESKRIPSI
                            Text(
                              t(
                                "Kelola operasional harian dengan efisien dalam satu ruang kerja digital.",
                                "Manage daily operations efficiently in one digital workspace.",
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.text,
                                height: 1.6,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  /// 4. ACTION BUTTONS
                  Column(
                    children: [
                      _buildMainButton(
                        text: t("MASUK SEKARANG", "LOGIN NOW"),
                        onTap: () => Navigator.pushNamed(context, '/login'),
                      ),
                      const SizedBox(height: 12),
                      _buildSecondaryButton(
                        text: t("Buat Akun Staf", "Create Staff Account"),
                        onTap: () => Navigator.pushNamed(context, '/signup'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  /// 5. LANGUAGE SELECTOR (Desain Diperbarui Biar Lebih Kelihatan & Menonjol)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.white.withOpacity(0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _langOption("ID", !isEnglish, () => setState(() => isEnglish = false)),
                        _langOption("EN", isEnglish, () => setState(() => isEnglish = true)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Text(
                    "Shift Management System v2.4.0",
                    style: TextStyle(color: AppColors.sub, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 2,
          shadowColor: AppColors.primary.withOpacity(0.3),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({required String text, required VoidCallback onTap}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.7)),
          ),
          child: TextButton(
            onPressed: onTap,
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.text,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget Opsi Bahasa dengan Efek Pil/Capsule yang Jelas Terbaca
  Widget _langOption(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.text.withOpacity(0.6),
            fontWeight: active ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}