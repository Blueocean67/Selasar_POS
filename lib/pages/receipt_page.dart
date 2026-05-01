import 'package:flutter/material.dart';
import 'dart:math';

class ReceiptPage extends StatelessWidget {
  const ReceiptPage({super.key});

  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color textDark = Color(0xFF2D3329);
  static const Color scaffoldBg = Color(0xFFF8F9F2);

  String _generateTransactionID() {
    var random = Random();
    int id = random.nextInt(90000) + 10000;
    return "#SR-$id";
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Biar kasir harus klik tombol selesai/home
      child: Scaffold(
        backgroundColor: scaffoldBg,
        appBar: _buildAppBar(context),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            children: [
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                builder: (context, double value, child) {
                  return Opacity(
                    opacity: value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - value)),
                      child: child,
                    ),
                  );
                },
                child: _buildReceiptCard(),
              ),
              const SizedBox(height: 32),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false, // Hilangin back bawaan
      title: const Text(
        "STRUK DIGITAL",
        style: TextStyle(
          color: textDark, 
          fontWeight: FontWeight.w900, 
          fontSize: 12, 
          letterSpacing: 2
        ),
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06), 
            blurRadius: 30, 
            offset: const Offset(0, 15)
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.coffee_rounded, color: primaryGreen, size: 32),
          ),
          const SizedBox(height: 16),
          const Text(
            "SELASAR RUANG",
            style: TextStyle(
              fontSize: 22, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 4, 
              color: primaryGreen
            ),
          ),
          Text(
            "Premium Coffee & Comfort Space",
            style: TextStyle(
              fontSize: 10, 
              color: Colors.grey.shade500, 
              letterSpacing: 1
            ),
          ),
          
          const SizedBox(height: 32),
          _buildZigZagDivider(),

          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _receiptDetailRow("No. Pesanan", _generateTransactionID()),
                _receiptDetailRow("Tanggal", "01 Mei 2026"), // Update ke Mei sesuai progres lo
                _receiptDetailRow("Waktu", "20:00 WIB"),
                _receiptDetailRow("Kasir", "Fadilah"),
                _receiptDetailRow("Metode", "QRIS Selasar"),
              ],
            ),
          ),

          const Divider(indent: 32, endIndent: 32, thickness: 0.8),

          const Padding(
            padding: EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("RINCIAN PESANAN", 
                style: TextStyle(
                  fontSize: 10, 
                  fontWeight: FontWeight.w900, 
                  color: primaryGreen, 
                  letterSpacing: 1.5
                )
              ),
            ),
          ),
          
          const _OrderItemRow(name: "Signature Americano", qty: "1", price: "28.000"),
          const _OrderItemRow(name: "Kopi Gula Aren", qty: "2", price: "50.000"),
          const _OrderItemRow(name: "Croissant Almond", qty: "1", price: "22.000"),

          const SizedBox(height: 24),
          _buildZigZagDivider(),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
            child: Column(
              children: [
                _totalDetailRow("Subtotal", "100.000"),
                _totalDetailRow("Pajak (10%)", "10.000"),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _totalDetailRow("TOTAL BAYAR", "110.000", isBold: true, color: Colors.white),
                ),
              ],
            ),
          ),

          const Icon(Icons.view_week_rounded, size: 60, color: textDark),
          const SizedBox(height: 8),
          const Text("TERIMA KASIH", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 5)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildZigZagDivider() {
    return Row(
      children: List.generate(25, (index) => Expanded(
        child: Container(
          height: 6,
          margin: const EdgeInsets.symmetric(horizontal: 1.5),
          decoration: BoxDecoration(
            color: scaffoldBg,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      )),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            // Trigger download PDF simulasi
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Berhasil mengunduh struk PDF"), backgroundColor: primaryGreen)
            );
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text("UNDUH PDF", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 65),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 16),
        TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
          icon: const Icon(Icons.home_rounded),
          label: const Text("KEMBALI KE BERANDA", style: TextStyle(fontWeight: FontWeight.w900, color: primaryGreen)),
        ),
      ],
    );
  }

  Widget _receiptDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: textDark)),
        ],
      ),
    );
  }

  Widget _totalDetailRow(String label, String value, {bool isBold = false, Color color = textDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color)),
        Text("Rp $value", style: TextStyle(fontSize: isBold ? 22 : 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w800, color: color)),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final String name, qty, price;
  const _OrderItemRow({required this.name, required this.qty, required this.price});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        children: [
          Text("${qty}x", style: const TextStyle(fontWeight: FontWeight.w900, color: ReceiptPage.primaryGreen, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ReceiptPage.textDark))),
          Text("Rp $price", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: ReceiptPage.textDark)),
        ],
      ),
    );
  }
}