import 'package:flutter/material.dart';

class PaymentSuccessPage extends StatelessWidget {
  const PaymentSuccessPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ikon Berhasil
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFEDF0E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF4A5D3F),
                  size: 100,
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                "Pembayaran Berhasil!",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3329)),
              ),
              const SizedBox(height: 10),
              const Text(
                "Pesanan sedang diproses oleh baristamu.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 40),
              
              // Rincian Singkat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9F2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Total Bayar", style: TextStyle(color: Colors.grey)),
                        Text("Rp 110.000", style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("Metode", style: TextStyle(color: Colors.grey)),
                        Text("QRIS - Berhasil", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 50),

              // Tombol Aksi
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/receipt');
                },
                icon: const Icon(Icons.print),
                label: const Text("Cetak Struk"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5D3F),
                  minimumSize: const Size(double.infinity, 56),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  // Kembali ke Dashboard dan hapus semua history navigasi
                  Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  side: const BorderSide(color: Color(0xFF4A5D3F)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text("Kembali ke Dashboard", style: TextStyle(color: Color(0xFF4A5D3F))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}