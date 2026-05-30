import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

// Pastikan path import main.dart ini sesuai dengan struktur project kamu
import '../main.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({super.key});

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryGreen = Color(0xFF435334);
  static const Color sage = Color(0xFF9EB384);
  static const Color cream = Color(0xFFF7F8F3);
  static const Color textPrimary = Color(0xFF2D3329);

  late AnimationController _controller;
  late String _cachedRefId;
  final _supabase = Supabase.instance.client;

  bool _isTransactionProcessed = false;
  bool _isDataInitialized = false;

  String _customerName = "PELANGGAN";
  String _tableNumber = "--";
  String _cashierName = "STAFF KASIR"; // Menyimpan nama kasir operasional penanggung jawab
  String _paymentMethod = "Tunai";
  double _subtotal = 0;
  double _discount = 0;
  double _tax = 0;
  double _totalPayable = 0;
  double _cashAmount = 0;
  double _changeAmount = 0;
  String _bankName = "";
  String _referenceNumber = "";
  String _appliedPromoCode = "";
  List<dynamic> _itemsOrdered = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _controller.forward();
    _cachedRefId = _generateRef();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isDataInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;

      if (args is Map<String, dynamic>) {
        _customerName = args['customer_name'] ?? "PELANGGAN";
        _tableNumber = args['table_number'] ?? "--";
        _cashierName = args['cashier_name'] ?? "STAFF KASIR"; // Parsing nama kasir otomatis dari hulu setup order
        _subtotal = (args['subtotal'] as num?)?.toDouble() ?? 0;
        _discount = (args['discount'] as num?)?.toDouble() ?? 0;
        _tax = (args['tax'] as num?)?.toDouble() ?? 0;
        _totalPayable = (args['total'] as num?)?.toDouble() ?? (args['total_price'] as num?)?.toDouble() ?? 0;
        _paymentMethod = args['payment_method'] ?? "Tunai";
        _cashAmount = (args['cash_amount'] as num?)?.toDouble() ?? (args['cash'] as num?)?.toDouble() ?? 0;
        _changeAmount = (args['change'] as num?)?.toDouble() ?? 0;
        _bankName = args['bank_name'] ?? "";
        _referenceNumber = args['reference_number'] ?? "";
        _appliedPromoCode = args['applied_promo_code'] ?? args['promo_code'] ?? "";
        _itemsOrdered = args['items'] ?? [];
      }
      _isDataInitialized = true;
      
      if (_itemsOrdered.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _finalizeTransactionFlow();
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _generateRef() =>
      "SR-${Random().nextInt(999999).toString().padLeft(6, '0')}";

  Future<void> _finalizeTransactionFlow() async {
    if (_isTransactionProcessed) return;
    _isTransactionProcessed = true;

    try {
      final String timestamp = DateTime.now().toIso8601String();

      String productSummary = _itemsOrdered.map((item) {
        final name = item['name'] ?? item['menu_name'] ?? 'Menu';
        final qty = item['quantity'] ?? item['qty'] ?? 1;
        return "$name ($qty)";
      }).join(', ');

      int totalItemsCount = _itemsOrdered.fold(0, (sum, item) {
        final qty = item['quantity'] ?? item['qty'] ?? 1;
        return sum + (qty as int);
      });

      // --- JEMBATAN SINKRONISASI UTAMA: KIRIM DATA KE HISTORY & AKSIKAN NOTIFIKASI ---
      List<Map<String, dynamic>> structuredMenuItems = _itemsOrdered.map((item) {
        return {
          'id': item['id']?.toString() ?? '',
          'name': item['name'] ?? item['menu_name'] ?? 'Menu',
          'qty': item['quantity'] ?? item['qty'] ?? 1,
          'price': (item['price'] as num?)?.toInt() ?? 0,
          'note': item['note'] ?? '',
          'image': item['image'] ?? item['image_url'] ?? '',
          'category': item['category'] ?? '',
        };
      }).toList();

      // Panggil fungsi manager state pusat agar pesanan ini langsung masuk ke tab 'PROSES' di riwayat secara realtime
      await context.read<OrderHistoryManager>().addOrder({
        'id': _cachedRefId,
        'customer_name': _customerName,
        'table_number': _tableNumber,
        'cashier_name': _cashierName,
        'total_price': _totalPayable.toInt(),
        'subtotal': _subtotal.toInt(),
        'discount': _discount.toInt(),
        'tax': _tax.toInt(),
        'items_count': totalItemsCount,
        'payment_method': _paymentMethod,
        'applied_promo_code': _appliedPromoCode,
        'cash_amount': _cashAmount > 0 ? _cashAmount.toInt() : _totalPayable.toInt(),
        'change': _changeAmount.toInt(),
        'items': structuredMenuItems, 
        'created_at': timestamp,
        'status': 'Proses', // Default masuk ke tab Proses antrean dapur/barista
      });

      // 1. Sinkronisasi tabel utama 'transactions' Supabase (Nama Kasir dipisah secara tepat dari Pelanggan)
      await _supabase.from('transactions').insert({
        'id': _cachedRefId,
        'created_at': timestamp,
        'total_price': _totalPayable.toInt(),
        'payment_status': 'SUCCESS',
        'cashier_name': _cashierName, // Memasukkan operator kasir asli ke database riil
        'items_count': totalItemsCount,
        'product_summary': productSummary,
      });

      // 2. Sinkronisasi tabel backup 'orders' Supabase
      await _supabase.from('orders').insert({
        'id': _cachedRefId,
        'customer_name': _customerName,
        'table_number': _tableNumber,
        'cashier_name': _cashierName,
        'payment_method': _paymentMethod,
        'subtotal': _subtotal.toInt(),
        'discount': _discount.toInt(),
        'tax': _tax.toInt(),
        'total_price': _totalPayable.toInt(),
        'total': _totalPayable.toInt(),
        'cash_amount': _cashAmount > 0 ? _cashAmount.toInt() : _totalPayable.toInt(),
        'change': _changeAmount.toInt(),
        'bank_name': _bankName,
        'reference_number': _referenceNumber,
        'applied_promo_code': _appliedPromoCode,
        'items': structuredMenuItems, 
        'status': 'Selesai',
        'order_status': 'Selesai',
        'payment_status': 'Selesai',
        'created_at': timestamp,
      });

      // 3. Automasi Pengurangan Stok Real-Time
      for (var item in _itemsOrdered) {
        final String menuName = item['name'] ?? item['menu_name'] ?? '';
        final int qtyBought = item['quantity'] ?? item['qty'] ?? item['count'] ?? 1;

        if (menuName.isNotEmpty) {
          final List<dynamic> menuCheck = await _supabase
              .from('menus')
              .select('id, stock')
              .eq('name', menuName);

          if (menuCheck.isNotEmpty) {
            final currentStock = menuCheck.first['stock'] ?? 20;
            final targetId = menuCheck.first['id'];
            
            if (currentStock != 9999) {
              int newStock = (currentStock as int) - qtyBought;
              if (newStock < 0) newStock = 0;

              await _supabase
                  .from('menus')
                  .update({'stock': newStock})
                  .eq('id', targetId);
            }
          }
        }
      }

      // 4. Bersihkan data keranjang belanja
      try {
        await _supabase.from('cart').delete().neq('id', '0');
      } catch (_) {}

    } catch (e) {
      debugPrint("Transaction pipeline background sync executed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: cream,
        body: Stack(
          children: [
            Positioned(
              top: -80,
              left: -40,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: sage.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -120,
              right: -50,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryGreen.withOpacity(0.08),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Lottie.asset(
                'assets/lottie/congratulation.json',
                repeat: false,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox(),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.95),
                              sage.withOpacity(0.18),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGreen.withOpacity(0.12),
                              blurRadius: 45,
                              spreadRadius: 8,
                            )
                          ],
                        ),
                        child: Lottie.asset(
                          'assets/lottie/success.json',
                          repeat: false,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.check_circle_rounded,
                            size: 80,
                            color: primaryGreen,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      FadeTransition(
                        opacity: _controller,
                        child: Column(
                          children: [
                            const Text(
                              "Pembayaran Berhasil",
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w900,
                                color: textPrimary,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              "Pesanan atas nama ${_customerName.toUpperCase()} (Meja $_tableNumber)\nsedang diproses oleh barista. Nikmati suasana Selasar Ruang ☕",
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF8E9775),
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _PaymentDetailCard(
                        refId: _cachedRefId,
                        subtotal: "Rp ${_subtotal.toInt()}",
                        discount: _discount > 0 ? "Rp ${_discount.toInt()}" : null,
                        tax: _tax > 0 ? "Rp ${_tax.toInt()}" : null,
                        total: "Rp ${_totalPayable.toInt()}",
                        method: _paymentMethod,
                        cashAmount: _cashAmount > 0 ? "Rp ${_cashAmount.toInt()}" : (_paymentMethod == "Tunai" ? "Rp ${_totalPayable.toInt()}" : null),
                        change: _changeAmount > 0 ? "Rp ${_changeAmount.toInt()}" : (_paymentMethod == "Tunai" ? "Rp 0" : null),
                        bankName: _bankName,
                        referenceNumber: _referenceNumber,
                        appliedPromoCode: _appliedPromoCode,
                        items: _itemsOrdered,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton.icon(
                        onPressed: () {
                          // --- NAVIGASI KE RECEIPT PAGE SECARA SINKRON DENGAN ARGUMEN LENGKAP ---
                          Navigator.pushNamed(
                            context, 
                            '/receipt',
                            arguments: {
                              'transaction_id': _cachedRefId,
                              'customer_name': _customerName,
                              'table_number': _tableNumber,
                              'cashier_name': _cashierName, // Meneruskan parameter nama kasir ke struk cetak
                              'subtotal': _subtotal,
                              'discount': _discount,
                              'tax': _tax,
                              'total': _totalPayable,
                              'payment_method': _paymentMethod,
                              'cash_amount': _cashAmount > 0 ? _cashAmount : _totalPayable,
                              'change': _changeAmount,
                              'bank_name': _bankName,
                              'reference_number': _referenceNumber,
                              'applied_promo_code': _appliedPromoCode,
                              'items': _itemsOrdered, 
                            }
                          );
                        },
                        icon: const Icon(Icons.receipt_long_rounded),
                        label: const Text(
                          "LIHAT STRUK DIGITAL",
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryGreen,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamedAndRemoveUntil(
                            context,
                            '/dashboard',
                            (route) => false,
                          );
                        },
                        child: const Text(
                          "Kembali ke Dashboard",
                          style: TextStyle(
                            color: primaryGreen,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
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
  final String subtotal;
  final String? discount;
  final String? tax;
  final String total;
  final String method;
  final String? cashAmount;
  final String? change; 
  final String bankName;
  final String referenceNumber;
  final String appliedPromoCode;
  final List<dynamic> items; 

  const _PaymentDetailCard({
    required this.refId,
    required this.subtotal,
    this.discount,
    this.tax,
    required this.total,
    required this.method,
    this.cashAmount,
    this.change,
    required this.bankName,
    required this.referenceNumber,
    required this.appliedPromoCode,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.7),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9EB384).withOpacity(0.08),
            blurRadius: 28,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow("ID Transaksi", refId),
          const SizedBox(height: 12),
          _buildRow("Metode Pembayaran", method),
          
          if (method == "QRIS") ...[
            const SizedBox(height: 12),
            _buildRow("Status QRIS", "BERHASIL (PAID)"),
          ] else if (method.startsWith("Debit")) ...[
            if (bankName.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRow("Nama Bank", bankName.toUpperCase()),
            ],
            if (referenceNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildRow("No. Referensi", referenceNumber),
            ],
          ],

          if (appliedPromoCode.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRow("Voucher Dipakai", appliedPromoCode),
          ],
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFE8EBDD), thickness: 1),
          ),
          
          const Text(
            "Rincian Menu:",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF435334)),
          ),
          const SizedBox(height: 10),
          items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    "Tidak ada detail pesanan", 
                    style: TextStyle(color: Colors.grey, fontSize: 13, fontStyle: FontStyle.italic),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, idx) {
                    final item = items[idx];
                    if (item == null) return const SizedBox();
                    
                    String name = item['name'] ?? item['menu_name'] ?? 'Menu';
                    int qty = item['quantity'] ?? item['qty'] ?? item['count'] ?? 1;
                    int singlePrice = (item['price'] as num?)?.toInt() ?? 0;
                    int totalItemPrice = singlePrice * qty;
                    String note = item['note'] ?? '';
                    String imgUrl = item['image'] ?? item['image_url'] ?? '';

                    bool isNetworkImage = imgUrl.startsWith('http') || imgUrl.startsWith('https');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: imgUrl.isNotEmpty
                                ? (isNetworkImage 
                                    ? Image.network(imgUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImg())
                                    : Image.asset(imgUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _fallbackImg()))
                                : _fallbackImg(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$name x$qty",
                                  style: const TextStyle(color: Color(0xFF2D3329), fontSize: 13, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (note.isNotEmpty)
                                  Text(
                                    "Note: $note",
                                    style: const TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Rp $totalItemPrice",
                            style: const TextStyle(color: Color(0xFF2D3329), fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  },
                ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Divider(color: Color(0xFFE8EBDD), thickness: 1),
          ),

          _buildRow("Subtotal", subtotal),
          if (discount != null) ...[
            const SizedBox(height: 8),
            _buildRow("Diskon Promo", "- $discount"),
          ],
          if (tax != null) ...[
            const SizedBox(height: 8),
            _buildRow("Pajak", tax!),
          ],
          if (cashAmount != null) ...[
            const SizedBox(height: 8),
            _buildRow("Tunai Dibayar", cashAmount!),
          ],
          if (change != null) ...[
            const SizedBox(height: 8),
            _buildRow("Kembalian", change!),
          ],
          const SizedBox(height: 12),
          _buildRow("Total Akhir", total, isTotal: true),
        ],
      ),
    );
  }

  Widget _fallbackImg() => Container(
        width: 40,
        height: 40,
        color: const Color(0xFFEDF0E9),
        child: const Icon(Icons.image, size: 20, color: Colors.grey),
      );

  Widget _buildRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF8E9775),
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isTotal
                ? const Color(0xFF435334)
                : const Color(0xFF2D3329),
            fontWeight: FontWeight.w900,
            fontSize: isTotal ? 20 : 13,
          ),
        ),
      ],
    );
  }
}
