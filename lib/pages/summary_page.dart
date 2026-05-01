import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Buat format rupiah

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);
  static const Color textDark = Color(0xFF2D3329);

  String selectedMethod = "Tunai";
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _debitRefController = TextEditingController();
  
  // Nanti ini ambil dari arguments Navigator (cart data)
  int totalBayar = 110000; 
  int kembalian = 0;

  @override
  void dispose() {
    _cashController.dispose();
    _debitRefController.dispose();
    super.dispose();
  }

  // Hitung kembalian & auto format rupiah
  void _calculateChange(String value) {
    if (value.isEmpty) {
      setState(() => kembalian = 0);
      return;
    }
    int input = int.tryParse(value.replaceAll('.', '')) ?? 0;
    setState(() {
      kembalian = input - totalBayar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgSurface,
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Ringkasan Pesanan", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryGreen)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGuestInfoCard(),
            const SizedBox(height: 32),
            _buildSectionHeader("Daftar Pesanan"),
            const SizedBox(height: 16),
            _buildOrderList(),
            const SizedBox(height: 20),
            _buildPriceSummary(),
            const SizedBox(height: 32),
            _buildSectionHeader("Metode Pembayaran"),
            const SizedBox(height: 16),
            _buildPaymentOptions(),
            const SizedBox(height: 24),
            _buildDynamicPaymentDetail(), 
            const SizedBox(height: 40),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(),
    );
  }

  Widget _buildDynamicPaymentDetail() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: selectedMethod == "Tunai"
          ? _buildCashInput()
          : selectedMethod == "QRIS"
              ? _buildQRISView()
              : _buildDebitInput(),
    );
  }

  Widget _buildCashInput() {
    return Container(
      key: const ValueKey("cash"),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)]
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("UANG DITERIMA (CASH)", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _cashController,
            keyboardType: TextInputType.number,
            onChanged: _calculateChange,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: primaryGreen),
            decoration: InputDecoration(
              hintText: "0",
              prefixText: "Rp ",
              filled: true,
              fillColor: bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
          if (_cashController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Kembalian:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                  Text(
                    kembalian < 0 ? "Kurang Rp ${kembalian.abs()}" : "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(kembalian)}", 
                    style: TextStyle(
                      fontWeight: FontWeight.w900, 
                      color: kembalian < 0 ? Colors.red : primaryGreen, 
                      fontSize: 18
                    )
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQRISView() {
    return Container(
      key: const ValueKey("qris"),
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: primaryGreen.withOpacity(0.1))
      ),
      child: Column(
        children: [
          const Text("SCAN QRIS DANA SELASAR", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
          const SizedBox(height: 20),
          // Gue pake link placeholder QR DANA, lo bisa ganti path asset lo nanti
          Image.network(
            "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=DANA_PAYMENT_SELASAR", 
            width: 180, 
            height: 180,
          ),
          const SizedBox(height: 20),
          const Text("Pastikan nominal sesuai total", style: TextStyle(fontSize: 11, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildDebitInput() {
    return Container(
      key: const ValueKey("debit"),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("REFERENSI EDC / BANK", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          TextField(
            controller: _debitRefController,
            decoration: InputDecoration(
              hintText: "Nama Bank / 4 Digit Terakhir",
              filled: true,
              fillColor: bgSurface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: textDark, letterSpacing: 1));
  }

  Widget _buildGuestInfoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [primaryGreen, Color(0xFF6A8455)]),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))]
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("PEMESAN", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("Budi Sudarsono", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text("MEJA", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
              Text("04", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderList() {
    return const Column(
      children: [
        _OrderItemTile(name: "Signature Americano", qty: "1x", price: "Rp 28.000", image: "assets/images/Amerikano.jpg"),
        _OrderItemTile(name: "Kopi Gula Aren", qty: "2x", price: "Rp 50.000", image: "assets/images/kopigulaaren.webp"),
      ],
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
      child: Column(
        children: [
          const _PriceRow(label: "Subtotal", value: "Rp 100.000"),
          const SizedBox(height: 12),
          const _PriceRow(label: "Pajak (10%)", value: "Rp 10.000"),
          const Divider(height: 32),
          _PriceRow(label: "TOTAL", value: "Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalBayar)}", isTotal: true),
        ],
      ),
    );
  }

  Widget _buildPaymentOptions() {
    return Row(
      children: [
        _PaymentButton(
          icon: Icons.payments_rounded,
          label: "Tunai",
          isSelected: selectedMethod == "Tunai",
          onTap: () => setState(() => selectedMethod = "Tunai"),
        ),
        const SizedBox(width: 12),
        _PaymentButton(
          icon: Icons.qr_code_scanner_rounded,
          label: "QRIS",
          isSelected: selectedMethod == "QRIS",
          onTap: () => setState(() => selectedMethod = "QRIS"),
        ),
        const SizedBox(width: 12),
        _PaymentButton(
          icon: Icons.credit_card_rounded,
          label: "Debit",
          isSelected: selectedMethod == "Debit",
          onTap: () => setState(() => selectedMethod = "Debit"),
        ),
      ],
    );
  }

  Widget _buildBottomAction() {
    // Validasi tombol: Kalau tunai, uang harus cukup
    bool canPay = true;
    if (selectedMethod == "Tunai" && kembalian < 0) canPay = false;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 34),
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      child: ElevatedButton(
        onPressed: !canPay ? null : () => Navigator.pushNamed(context, '/payment_success'),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          minimumSize: const Size(double.infinity, 64),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: Text(canPay ? "Konfirmasi & Bayar" : "Uang Kurang!", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
      ),
    );
  }
}

// Komponen Pendukung
class _OrderItemTile extends StatelessWidget {
  final String name, qty, price, image;
  const _OrderItemTile({required this.name, required this.qty, required this.price, required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.black.withOpacity(0.04))),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.asset(image, width: 45, height: 45, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.coffee))),
          const SizedBox(width: 16),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
              Text(qty, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ],
          )),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4A5D3F))),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label, value;
  final bool isTotal;
  const _PriceRow({required this.label, required this.value, this.isTotal = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: isTotal ? Colors.black : Colors.grey, fontWeight: isTotal ? FontWeight.w900 : FontWeight.normal)),
        Text(value, style: TextStyle(fontSize: isTotal ? 22 : 14, fontWeight: FontWeight.w900, color: isTotal ? const Color(0xFF4A5D3F) : Colors.black)),
      ],
    );
  }
}

class _PaymentButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentButton({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF4A5D3F) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? Colors.transparent : Colors.black12),
            boxShadow: isSelected ? [BoxShadow(color: const Color(0xFF4A5D3F).withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))] : [],
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : const Color(0xFF4A5D3F), size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF4A5D3F), fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        ),
      ),
    );
  }
}