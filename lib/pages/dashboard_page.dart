import 'package:flutter/material.dart';

// --- STYLE CONSTANTS ---
class AppColors {
  static const primaryGreen = Color(0xFF4A5D3F);
  static const secondaryGreen = Color(0xFFA3B18A);
  static const background = Color(0xFFF8F9F2);
  static const textPrimary = Color(0xFF2D3329);
  static const textSecondary = Color(0xFF7A7A7A);
  static const accentGold = Color(0xFFBC8E5B); 
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.menu, color: AppColors.primaryGreen),
        title: const Text("Selasar Ruang", 
          style: TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile'),
              child: const CircleAvatar(
                backgroundImage: AssetImage('assets/images/user_profile.png'), 
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            const Text("Dashboard\nRingkasan", 
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.textPrimary, height: 1.2)),
            const SizedBox(height: 20),
            
            _buildMainStatsCard(),
            
            const SizedBox(height: 24),
            const Text("Akses Cepat", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _quickAccessItem(context, Icons.shopping_cart_outlined, "Mulai Pesanan", '/setup_order'),
                _quickAccessItem(context, Icons.history, "Riwayat", '/history'),
                _quickAccessItem(context, Icons.restaurant_menu, "Gallery", '/gallery'),
                _quickAccessItem(context, Icons.bar_chart, "Laporan", '/report'),
              ],
            ),
            
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Rekomendasi Hari Ini", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                TextButton(onPressed: () {}, child: const Text("Lihat Semua", style: TextStyle(color: AppColors.primaryGreen))),
              ],
            ),
            
            const MenuCard(
              title: "Signature Americano Selasar",
              price: "Rp 28.000",
              desc: "Kopi espresso rasa klasik yang ringan dan lembut.",
              imagePath: "assets/images/Amerikano.jpg", 
              tag: "POPULER",
            ),

            const MenuCard(
              title: "Aceh Gayo v60",
              price: "Rp 30.000",
              desc: "Biji Kopi Arabika Aceh Gayo Natural Specialty Coffee.",
              imagePath: "assets/images/acehgayov60.png", 
              tag: "MANUAL BREW",
            ),
            const SizedBox(height: 100), 
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // REVISI: 25 Transaksi dibuat terpisah dan aesthetic
  Widget _buildMainStatsCard() {
    return Stack(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("TOTAL PENJUALAN HARI INI", 
                style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text("Rp 850.000", 
                style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                children: [
                  _smallStat("Target", "Rp 1.2M"),
                  const SizedBox(width: 40),
                  _smallStat("Sisa", "Rp 350rb"),
                ],
              )
            ],
          ),
        ),
        // Badge Transaksi melayang di pojok
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: const Column(
              children: [
                Text("25", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                Text("Orders", style: TextStyle(color: Colors.white70, fontSize: 8, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _smallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
        Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _quickAccessItem(BuildContext context, IconData icon, String label, String route) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.black.withOpacity(0.03)), borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.primaryGreen, size: 28),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // REVISI: Logika Pilih Aksi untuk Tombol ORDERS
  void _showOrderOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("Pilih Menu Order", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEDF0E9), child: Icon(Icons.add_shopping_cart, color: AppColors.primaryGreen)),
              title: const Text("Buat Pesanan Baru", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Input data meja & pelanggan"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/setup_order');
              },
            ),
            ListTile(
              leading: const CircleAvatar(backgroundColor: Color(0xFFEDF0E9), child: Icon(Icons.image_search, color: AppColors.primaryGreen)),
              title: const Text("Lihat Gallery Menu", style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text("Katalog foto menu lengkap"),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/gallery');
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 25, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.grid_view_rounded, "HOME", true, '/dashboard'),
          // Tombol ORDERS sekarang memanggil Modal Pilihan
          _navItem(context, Icons.receipt_long_outlined, "ORDERS", false, 'modal'),
          _navItem(context, Icons.history, "HISTORY", false, '/history'),
          _navItem(context, Icons.person_outline, "PROFILE", false, '/profile'),
        ],
      ),
    );
  }

  Widget _navItem(BuildContext context, IconData icon, String label, bool isActive, String route) {
    return GestureDetector(
      onTap: () {
        if (route == 'modal') {
          _showOrderOptions(context);
        } else if (!isActive) {
          Navigator.pushNamed(context, route);
        }
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isActive ? AppColors.primaryGreen : Colors.grey[400], size: 26),
          const SizedBox(height: 4),
          if (isActive) 
            Container(height: 4, width: 4, decoration: const BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle))
          else 
            Text(label, style: TextStyle(fontSize: 9, color: Colors.grey[400], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class MenuCard extends StatelessWidget {
  final String title, price, desc, imagePath, tag;
  const MenuCard({super.key, required this.title, required this.price, required this.desc, required this.imagePath, required this.tag});

  @override
  Widget build(BuildContext context) {
    Color tagBg = AppColors.secondaryGreen.withOpacity(0.2);
    Color tagText = AppColors.primaryGreen;

    if (tag.toUpperCase() == "MANUAL BREW") {
      tagBg = AppColors.accentGold.withOpacity(0.2);
      tagText = AppColors.accentGold;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(imagePath, height: 180, width: double.infinity, fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(height: 180, color: Colors.grey[100], child: const Icon(Icons.broken_image, color: Colors.grey)),
            ),
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(color: tagBg, borderRadius: BorderRadius.circular(10)),
                child: Text(tag, style: TextStyle(color: tagText, fontSize: 10, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 6),
          Text(desc, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4)),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryGreen)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Text("Tambah", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    SizedBox(width: 8),
                    Icon(Icons.add_circle_outline, color: Colors.white, size: 16),
                  ],
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}