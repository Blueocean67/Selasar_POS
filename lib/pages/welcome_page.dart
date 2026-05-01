import 'package:flutter/material.dart';
import 'dart:ui';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  // Foto Cafe Aesthetic Unsplash
  final String welcomeBg = "https://images.unsplash.com/photo-1509042239860-f550ce710b93?q=80&w=1887&auto=format&fit=crop";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2D3329), // Army Green Base
      body: Stack(
        children: [
          // 1. Full Background Photo dengan Overlay Gelap
          Positioned.fill(
            child: Image.network(
              welcomeBg,
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(color: const Color(0xFF0D110C).withOpacity(0.6)),
          ),

          // 2. Konten Utama
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
              child: Column(
                children: [
                  const Spacer(),
                  // Logo Selasar
                  Image.asset('assets/images/SelasarLogo.png', width: 150),
                  const SizedBox(height: 20),
                  const Text(
                    "Selasar Ruang",
                    style: TextStyle(color: Color(0xFFC5D1B5), fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const Text(
                    "Internal Management Access",
                    style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1),
                  ),
                  const Spacer(),
                  
                  // 3. Pilihan Masuk atau Daftar (Glassmorphism Card)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(25),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "Halo, Selamat Datang!",
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "Silahkan pilih akses untuk melanjutkan pekerjaan anda hari ini.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 30),
                            
                            // Tombol Masuk
                            ElevatedButton(
                              onPressed: () => Navigator.pushNamed(context, '/login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4A5D3F),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                minimumSize: const Size(double.infinity, 55),
                              ),
                              child: const Text("MASUK KE SISTEM", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Tombol Daftar
                            OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/signup'),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Color(0xFFC5D1B5)),
                                foregroundColor: const Color(0xFFC5D1B5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                minimumSize: const Size(double.infinity, 55),
                              ),
                              child: const Text("BUAT AKUN BARU", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}