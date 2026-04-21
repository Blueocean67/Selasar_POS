import 'package:flutter/material.dart';

class OrderSummaryPage extends StatelessWidget {
  const OrderSummaryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5D3F), size: 20),
          onPressed: () => Navigator.pop(context), // Sesuai fungsinya untuk kembali
        ),
        title: const Text(
          "Ringkasan Pesanan",
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info Meja & Pemesan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF4A5D3F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("PEMESAN", style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text("Budi Sudarsono", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("MEJA", style: TextStyle(color: Colors.white70, fontSize: 10)),
                      Text("Meja 04", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            
            const Text("Daftar Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),

            // List Item Pesanan
            _buildOrderItem("Signature Americano", "1x", "Rp 28.000"),
            _buildOrderItem("Kopi Gula Aren", "2x", "Rp 50.000"),
            _buildOrderItem("Croissant Almond", "1x", "Rp 22.000"),
            
            const Divider(height: 40, thickness: 1),

            // Rincian Biaya
            _buildPriceRow("Subtotal", "Rp 100.000"),
            _buildPriceRow("Pajak (10%)", "Rp 10.000"),
            const SizedBox(height: 10),
            _buildPriceRow("TOTAL PEMBAYARAN", "Rp 110.000", isTotal: true),
            
            const SizedBox(height: 30),
            const Text("Metode Pembayaran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 15),
            
            // Opsi Pembayaran
            Row(
              children: [
                _paymentOption(Icons.payments_outlined, "Tunai", true),
                const SizedBox(width: 12),
                _paymentOption(Icons.qr_code_scanner, "QRIS", false),
                const SizedBox(width: 12),
                _paymentOption(Icons.credit_card, "Debit", false),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))]
        ),
        child: ElevatedButton(
          onPressed: () {
            // PERBAIKAN: Navigasi ke halaman sukses pembayaran diletakkan di sini
            Navigator.pushNamed(context, '/payment_success');
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A5D3F),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 60),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: const Text("Konfirmasi & Bayar", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ),
    );
  }

  Widget _buildOrderItem(String name, String qty, String price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEDF0E9), borderRadius: BorderRadius.circular(10)),
            child: Text(qty, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F))),
          ),
          const SizedBox(width: 15),
          Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w500))),
          Text(price, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            color: isTotal ? const Color(0xFF2D3329) : Colors.grey,
          )),
          Text(value, style: TextStyle(
            fontSize: isTotal ? 20 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            color: isTotal ? const Color(0xFF4A5D3F) : const Color(0xFF2D3329),
          )),
        ],
      ),
    );
  }

  Widget _paymentOption(IconData icon, String label, bool isSelected) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF4A5D3F) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFEDF0E9)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? Colors.white : const Color(0xFF4A5D3F)),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontSize: 12, 
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : const Color(0xFF4A5D3F)
            )),
          ],
        ),
      ),
    );
  }
}