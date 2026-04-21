import 'package:flutter/material.dart';

class SetupOrderPage extends StatelessWidget {
  const SetupOrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false, // Biar lebih estetik di kiri
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5D3F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Setup Your Order Info",
          style: TextStyle(
            color: Color(0xFF2D3329),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Prepare the sanctuary for our guest. Please ensure all details are recorded accurately.",
              style: TextStyle(color: Color(0xFF7A7A7A), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 30),
            
            // Container Form (Putih)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel("NAMA KASIR"),
                  _buildReadOnlyField("Adhitya Pradana", Icons.badge_outlined),
                  
                  const SizedBox(height: 20),
                  _buildLabel("NAMA PEMESAN"),
                  TextField(
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Enter guest name",
                      hintStyle: const TextStyle(color: Colors.black26),
                      prefixIcon: const Icon(Icons.person_outline, size: 20, color: Color(0xFF4A5D3F)),
                      filled: true,
                      fillColor: const Color(0xFFF1F4EE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  _buildLabel("NOMOR MEJA"),
                  // Grid Nomor Meja
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1,
                    ),
                    itemCount: 8,
                    itemBuilder: (context, index) {
                      bool isSelected = index == 0; // Logika pilihan meja nanti di sini
                      return Container(
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF4A5D3F) : const Color(0xFFEDF0E9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            "0${index + 1}",
                            style: TextStyle(
                              color: isSelected ? Colors.white : const Color(0xFF2D3329),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 30),
                  
                  // Tombol Mulai Pesanan (DIBERSIHKAN)
                  ElevatedButton(
                    onPressed: () {
                      // Pastikan route '/menu' sudah terdaftar di main.dart
                      Navigator.pushNamed(context, '/menu');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4A5D3F),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Mulai Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            
            // Info Card (Ambient Info) - DENGAN LINK STABIL
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EDD9),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Morning Ambience",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A5D3F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Current capacity: 65% occupied. Prefer Window Seats for 2-4 guests.",
                          style: TextStyle(fontSize: 11, color: Colors.black.withOpacity(0.6)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=200',
                      width: 55,
                      height: 55,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 55, height: 55, color: Colors.white24,
                        child: const Icon(Icons.image, size: 20),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Color(0xFF4A5D3F),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildReadOnlyField(String value, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4EE),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: const Color(0xFF4A5D3F).withOpacity(0.5)),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF2D3329),
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          const Icon(Icons.check_circle, size: 16, color: Color(0xFFA3B18A)),
        ],
      ),
    );
  }
}