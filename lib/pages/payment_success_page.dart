import 'package:flutter/material.dart';
import 'dart:math';
import 'package:lottie/lottie.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color textPrimary = Color(0xFF2D3329);
  static const Color surfaceGreen = Color(0xFFF8F9F2);

  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generateRef() => "REF-${Random().nextInt(999999).toString().padLeft(6, '0')}";

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Biar kasir nggak sengaja back pas lagi proses
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // 1. Animasi Congratulation / Confetti (Background)
            // Pakai Lottie.asset biar kenceng dan anti-error merah
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset(
                'assets/lottie/congratulation.json', // Sesuaikan nama file lo
                repeat: false,
                fit: BoxFit.contain,
                width: double.infinity,
              ),
            ),

            Positioned(
              top: -100,
              right: -50,
              child: CircleAvatar(radius: 150, backgroundColor: surfaceGreen.withOpacity(0.5)),
            ),
            
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 2. Animasi Success (Centang Hidup)
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEDF0E9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.15),
                              blurRadius: 40,
                              spreadRadius: 10,
                            )
                          ],
                        ),
                        child: Lottie.asset(
                          'assets/lottie/success.json', // Animasi centang lo
                          repeat: false,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      TweenAnimationBuilder(
                        duration: const Duration(milliseconds: 800),
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, double value, child) {
                          return Opacity(opacity: value, child: child);
                        },
                        child: const Column(
                          children: [
                            Text(
                              "Sukses!",
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -1,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              "Pesanan Selasar sedang disiapkan.\nBaristamu sudah menerima notifikasi.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      _PaymentDetailCard(
                        refId: _generateRef(),
                        total: "Rp 110.000",
                        method: "QRIS Selasar",
                      ),

                      const SizedBox(height: 60),

                      // 4. Action Buttons
                      Column(
                        children: [
                          ElevatedButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/receipt'),
                            icon: const Icon(Icons.print_rounded),
                            label: const Text("CETAK STRUK DIGITAL", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryGreen,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 65),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () {
                              // Bersihkan stack dan balik ke dashboard
                              Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false);
                            },
                            child: const Text(
                              "Kembali ke Dashboard",
                              style: TextStyle(
                                color: primaryGreen,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDetailCard extends StatelessWidget {
  final String refId;
  final String total;
  final String method;

  const _PaymentDetailCard({
    required this.refId,
    required this.total,
    required this.method,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4EE),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Column(
        children: [
          _buildRow("ID Transaksi", refId),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.black12, thickness: 1),
          ),
          _buildRow("Metode Pembayaran", method),
          const SizedBox(height: 12),
          _buildRow("Total Dibayar", total, isTotal: true),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.black54,
            fontSize: 12,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal ? const Color(0xFF4A5D3F) : const Color(0xFF2D3329),
            fontWeight: FontWeight.w900,
            fontSize: isTotal ? 22 : 12,
          ),
        ),
      ],
    );
  }
}