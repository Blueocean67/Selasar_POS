import 'package:flutter/material.dart';
import '../theme/app_colors.dart'; // Import biar warnanya sinkron

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: AppColors.primary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Profil Kasir",
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 30),
            // Foto Profil & Nama
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage('assets/images/user_profile.png'), 
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Admin Selasar",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const Text(
                    "Kelompok 4 - Mobile App Dev",
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // SEKSI LAPORAN & EKSPORT (Tambahan Baru)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Laporan & Bisnis", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _profileMenuItem(
                          Icons.bar_chart_rounded, 
                          "Laporan Penjualan", 
                          onTap: () => Navigator.pushNamed(context, '/report'),
                        ),
                        const Divider(indent: 60, height: 1),
                        _profileMenuItem(
                          Icons.file_download_outlined, 
                          "Ekspor Data (PDF/Excel)", 
                          onTap: () => Navigator.pushNamed(context, '/report'), // Arahin ke report karena tombol download ada di sana
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Menu Pengaturan Lainnya
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Pengaturan Aplikasi", 
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      children: [
                        _profileMenuItem(Icons.person_outline, "Informasi Pribadi", onTap: () {}),
                        const Divider(indent: 60, height: 1),
                        _profileMenuItem(Icons.security_outlined, "Keamanan Akun", onTap: () {}),
                        const Divider(indent: 60, height: 1),
                        _profileMenuItem(Icons.language_outlined, "Bahasa (English/ID)", onTap: () {}),
                        const Divider(indent: 60, height: 1),
                        _profileMenuItem(Icons.help_outline, "Pusat Bantuan", onTap: () {}),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            
            // Tombol Logout
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFFE57373)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text(
                  "Keluar dari Akun",
                  style: TextStyle(color: Color(0xFFE57373), fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Selasar Ruang v1.0.4", style: TextStyle(color: Colors.grey, fontSize: 10)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _profileMenuItem(IconData icon, String title, {required VoidCallback onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
    );
  }
}