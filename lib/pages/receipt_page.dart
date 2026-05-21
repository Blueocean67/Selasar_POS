import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:selasar_pos/main.dart';


class ReceiptPage extends StatefulWidget {
  const ReceiptPage({super.key});

  static const Color primaryGreen = Color(0xFF435334);
  static const Color softOlive = Color(0xFF9EB384);
  static const Color textDark = Color(0xFF2D3329);
  static const Color textLight = Color(0xFF8E9775);
  static const Color scaffoldBg = Color(0xFFF7F8F3);
  static const Color glass = Colors.white;

  @override
  State<ReceiptPage> createState() => _ReceiptPageState();
}

class _ReceiptPageState extends State<ReceiptPage> {
  final _supabase = Supabase.instance.client;
  
  bool _isPrinting = false;
  bool _hasProcessedState = false;
  Map<String, dynamic> _liveDbTransactionData = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processIntegrationsAndStates();
    });
  }

  // INTEGRASI STATE POS REAL-TIME: DATABASE, STOK, DAN SUMMARY KONSISTEN
  Future<void> _processIntegrationsAndStates() async {
    if (_hasProcessedState) return;
    
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) return;

    setState(() => _hasProcessedState = true);
    final Map<String, dynamic> orderData = args;

    // Pengaman: Jangan proses jika transaksi kosong atau tidak memiliki ID
    final String targetTxId = orderData['transaction_id'] ?? orderData['id']?.toString() ?? '';
    if (targetTxId.isEmpty) return;

    try {
      // 1. Tarik Data Utama dari Single Source of Truth (Database Supabase)
      final dbData = await _supabase
          .from('transactions')
          .select()
          .eq('id', targetTxId)
          .maybeSingle();

      if (dbData != null && mounted) {
        setState(() {
          _liveDbTransactionData = dbData;
        });
      }

      // PARSING UNTUK DIKIRIM KE HISTORY STATE MANAGER (REAL-TIME NOTIFICATION)
      final String customerName = dbData?['customer_name'] ?? orderData['customer_name'] ?? orderData['customer'] ?? 'Pelanggan Selasar';
      
      int itemsCount = 0;
      if (orderData.containsKey('items')) {
        final List<dynamic> items = orderData['items'] is List ? orderData['items'] : [];
        itemsCount = items.length;
      } else if (dbData?['product_summary'] != null) {
        itemsCount = dbData!['product_summary'].toString().split(',').length;
      }
      if (itemsCount == 0) itemsCount = 1;

      final double finalTotal = double.tryParse((dbData?['total_price'] ?? orderData['total_price'] ?? 0).toString()) ?? 0.0;

      // MENYAMBUNGKAN & MEMASUKKAN DATA KE HISTORY PAGE VIA PROVIDER
      if (mounted) {
        try {
          context.read<OrderHistoryManager>().addLiveOrderFromCashier(
            customerName: customerName,
            totalPrice: finalTotal.toInt(),
            itemsCount: itemsCount,
          );
          
          // Memunculkan Notifikasi Banner Instan di Aplikasi
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Pesanan baru dari $customerName berhasil masuk ke Riwayat!"),
              backgroundColor: const Color(0xFF556B2F),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        } catch (providerError) {
          debugPrint("[History Link Error] OrderHistoryManager belum di-provide di context ini: $providerError");
        }
      }

      // 2. Automasi Sinkronisasi Pengurangan Stok
      if (orderData.containsKey('items')) {
        final List<dynamic> items = orderData['items'] is List ? orderData['items'] : [];
        for (var item in items) {
          if (item is Map) {
            final String itemId = item['id']?.toString() ?? '';
            final int qtyPurchased = int.tryParse(item['quantity'].toString()) ?? 
                                     int.tryParse(item['qty'].toString()) ?? 1;

            if (itemId.isNotEmpty) {
              final List<dynamic> menuCheck = await _supabase
                  .from('menus')
                  .select('stock')
                  .eq('id', itemId);

              if (menuCheck.isNotEmpty) {
                final int currentStock = menuCheck.first['stock'] ?? 20;
                if (currentStock < 9000) {
                  final int newStock = (currentStock - qtyPurchased).clamp(0, 9999);
                  await _supabase
                      .from('menus')
                      .update({'stock': newStock})
                      .eq('id', itemId);
                }
              }
            }
          }
        }
      }
      debugPrint("[POS Engine] Transaksi #$targetTxId terverifikasi sinkron di seluruh komponen dashboard.");
    } catch (e) {
      debugPrint("[POS Engine Error] Sinkronisasi database gagal: $e");
    }
  }

  // FITUR CETAK BLUETOOTH THERMAL
  Future<void> _simulateBluetoothPrint(Map<String, dynamic> txData) async {
    setState(() => _isPrinting = true);

    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Row(
            children: [
              Icon(Icons.bluetooth_connected, color: Colors.blue),
              SizedBox(width: 10),
              Text("Printer Connected", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.print, color: Colors.blue, size: 18),
                    SizedBox(width: 8),
                    Text("Target: Thermal_Printer_58mm", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 15),
              Text("Sedang mencetak struk transaksi #${txData['id'] ?? 'POS-Selasar'}...", 
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 10),
              LinearProgressIndicator(color: ReceiptPage.primaryGreen, backgroundColor: ReceiptPage.primaryGreen.withOpacity(0.1)),
            ],
          ),
        );
      },
    );

    await Future.delayed(const Duration(milliseconds: 2000));
    
    if (mounted) {
      Navigator.pop(context); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Struk #${txData['id'] ?? 'POS-Selasar'} Berhasil Dicetak ke Printer Kasir!"),
          backgroundColor: ReceiptPage.primaryGreen,
        ),
      );
      setState(() => _isPrinting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final Map<String, dynamic> orderData = (args is Map<String, dynamic>) ? args : {};

    final String transactionId = _liveDbTransactionData['id']?.toString() ?? 
        orderData['transaction_id'] ?? orderData['id']?.toString() ?? "SR-MANUAL";
    
    final String customerName = _liveDbTransactionData['customer_name'] ?? 
        orderData['customer_name'] ?? orderData['customer'] ?? 'Pelanggan Selasar';
    
    final String tableNumber = _liveDbTransactionData['table_number']?.toString() ?? 
        orderData['table_number']?.toString() ?? orderData['table']?.toString() ?? '--';
    
    final String paymentMethod = _liveDbTransactionData['payment_method'] ?? 
        orderData['payment_method'] ?? 'Tunai';

    final String cashierName = _liveDbTransactionData['cashier_name'] ?? 
        orderData['cashier_name'] ?? 'Kasir Utama';

    final List<Map<String, dynamic>> itemsList = [];
    double subtotal = 0.0;

    if (_liveDbTransactionData['product_summary'] != null) {
      String summary = _liveDbTransactionData['product_summary'].toString();
      List<String> rawItems = summary.split(',');
      for (var rawItem in rawItems) {
        if (rawItem.contains('(') && rawItem.contains(')')) {
          try {
            String name = rawItem.split('(')[0].trim();
            String qtyStr = rawItem.split('(')[1].replaceAll(')', '').trim();
            int qty = int.tryParse(qtyStr) ?? 1;
            
            itemsList.add({
              'name': name,
              'qty': qty,
              'price': 0.0, 
              'note': null
            });
          } catch (_) {}
        }
      }
    }

    if (itemsList.isEmpty || orderData.containsKey('items')) {
      itemsList.clear();
      final List<dynamic> customItemsList = orderData['items'] is List ? orderData['items'] : [];
      for (var item in customItemsList) {
        if (item is Map) {
          final double itemPrice = (item['price'] ?? item['harga'] ?? 0).toDouble();
          final int itemQty = int.tryParse(item['quantity'].toString()) ?? int.tryParse(item['qty'].toString()) ?? 1;
          subtotal += itemPrice * itemQty;

          itemsList.add({
            'name': item['name'] ?? item['nama_menu'] ?? 'Menu',
            'qty': itemQty,
            'price': itemPrice,
            'note': item['note']?.toString()
          });
        }
      }
    }

    if (subtotal == 0.0 && _liveDbTransactionData['total_price'] != null) {
      double dbTotal = double.tryParse(_liveDbTransactionData['total_price'].toString()) ?? 0.0;
      double dbDiscount = double.tryParse(_liveDbTransactionData['discount_amount'].toString()) ?? 0.0;
      subtotal = dbTotal + dbDiscount;
    }

    double discount = double.tryParse((_liveDbTransactionData['discount_amount'] ?? orderData['discount'] ?? orderData['diskon'] ?? 0).toString()) ?? 0.0;
    double total = double.tryParse((_liveDbTransactionData['total_price'] ?? orderData['total_price'] ?? (subtotal - discount)).toString()) ?? 0.0;
    if (total < 0) total = 0;
    
    double change = double.tryParse((orderData['change'] ?? orderData['kembalian'] ?? 0).toString()) ?? 0.0;
    final currency = NumberFormat.currency(locale: 'id', symbol: 'Rp ', decimalDigits: 0);
    
    String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    String formattedTime = DateFormat('HH:mm').format(DateTime.now()) + " WIB";
    
    var timeSource = _liveDbTransactionData['created_at'] ?? orderData['created_at'];
    if (timeSource != null) {
      try {
        DateTime parsedDate = DateTime.parse(timeSource.toString()).toLocal();
        formattedDate = DateFormat('dd MMMM yyyy').format(parsedDate);
        formattedTime = DateFormat('HH:mm').format(parsedDate) + " WIB";
      } catch (_) {}
    }

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: ReceiptPage.scaffoldBg,
        appBar: _buildAppBar(),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
          child: Column(
            children: [
              _buildReceiptCard(
                transactionId, customerName, tableNumber, paymentMethod, cashierName,
                itemsList, subtotal, discount, total, change, 
                formattedDate, formattedTime, currency
              ),
              const SizedBox(height: 32),
              _buildActionButtons(
                context, 
                () => _simulateBluetoothPrint({'id': transactionId})
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: ReceiptPage.scaffoldBg,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: const Text(
        "DIGITAL RECEIPT",
        style: TextStyle(
          color: ReceiptPage.textDark,
          fontWeight: FontWeight.w900,
          fontSize: 12,
          letterSpacing: 2.5,
        ),
      ),
    );
  }

  Widget _buildReceiptCard(
      String transactionId, String customerName, String tableNumber, String paymentMethod, String cashierName,
      List<Map<String, dynamic>> itemsList, double subtotal, double discount, double total, double change, 
      String dateStr, String timeStr, NumberFormat currency) {
    return Container(
      decoration: BoxDecoration(
        color: ReceiptPage.glass.withOpacity(0.92),
        borderRadius: BorderRadius.circular(34),
        border: Border.all(color: Colors.white.withOpacity(0.65)),
        boxShadow: [
          BoxShadow(
            color: ReceiptPage.primaryGreen.withOpacity(0.08),
            blurRadius: 35,
            offset: const Offset(0, 18),
          )
        ],
      ),
      child: Column(
        children: [
          const SizedBox(height: 36),
          Container(
            padding: const EdgeInsets.all(12),
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: ReceiptPage.softOlive.withOpacity(0.25), blurRadius: 25, offset: const Offset(0, 8))
              ],
            ),
            child: Image.asset(
              'assets/images/SelasarLogo.png',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.local_cafe_rounded,
                color: ReceiptPage.primaryGreen,
                size: 34,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            "SELASAR RUANG",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 4, color: ReceiptPage.primaryGreen),
          ),
          const SizedBox(height: 6),
          const Text(
            "Premium Coffee & Comfort Space",
            style: TextStyle(fontSize: 11, color: ReceiptPage.textLight, letterSpacing: 1.1),
          ),
          const SizedBox(height: 28),
          _buildZigZagDivider(),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                _receiptDetailRow("ID Transaksi", transactionId.substring(0, transactionId.length > 18 ? 18 : transactionId.length)),
                _receiptDetailRow("Pelanggan", customerName.toUpperCase()),
                _receiptDetailRow("Nomor Meja", "Meja $tableNumber"),
                _receiptDetailRow("Kasir/Admin", cashierName),
                _receiptDetailRow("Tanggal", dateStr),
                _receiptDetailRow("Waktu", timeStr),
                _receiptDetailRow("Metode", paymentMethod),
              ],
            ),
          ),
          Divider(indent: 32, endIndent: 32, color: ReceiptPage.softOlive.withOpacity(0.25)),
          const Padding(
            padding: EdgeInsets.fromLTRB(32, 24, 32, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "RINCIAN PESANAN",
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: ReceiptPage.primaryGreen, letterSpacing: 2),
              ),
            ),
          ),
          
          ...itemsList.map((item) => _OrderItemRow(
                name: item['name'] ?? 'Menu',
                qty: (item['qty'] ?? 1).toString(),
                price: item['price'] > 0 ? currency.format(item['price']) : '-',
                note: item['note'],
                currency: currency,
              )),

          const SizedBox(height: 26),
          _buildZigZagDivider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 30),
            child: Column(
              children: [
                _totalDetailRow("Subtotal", currency.format(subtotal)),
                if (discount > 0)
                  _totalDetailRow("Diskon Promo", "-${currency.format(discount)}", isDiscount: true),
                if (change > 0)
                  _totalDetailRow("Kembalian", currency.format(change)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [ReceiptPage.primaryGreen, ReceiptPage.softOlive]),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: _totalDetailRow(
                    "TOTAL BAYAR",
                    currency.format(total),
                    isBold: true,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_cafe_rounded, size: 56, color: ReceiptPage.softOlive),
          const SizedBox(height: 8),
          const Text(
            "TERIMA KASIH",
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 5, color: ReceiptPage.primaryGreen),
          ),
          const SizedBox(height: 8),
          const Text("Sampai jumpa di Selasar ☕", style: TextStyle(fontSize: 11, color: ReceiptPage.textLight)),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildZigZagDivider() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth > 0 ? constraints.maxWidth : 300;
        final int itemCount = (width / 14).floor().clamp(10, 40);
        return Row(
          children: List.generate(
            itemCount,
            (index) => Expanded(
              child: Container(
                height: 5,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  color: ReceiptPage.softOlive.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButtons(BuildContext context, VoidCallback onPrintBluetooth) {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isPrinting ? null : onPrintBluetooth,
          icon: _isPrinting 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Icon(Icons.print_rounded),
          label: Text(_isPrinting ? "MENCETAK STRUK..." : "PRINT STRUK via BLUETOOTH"),
          style: ElevatedButton.styleFrom(
            backgroundColor: ReceiptPage.primaryGreen,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            elevation: 0,
          ),
        ), 
        const SizedBox(height: 20),
        TextButton.icon(
          onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (route) => false),
          icon: const Icon(Icons.home_rounded),
          label: const Text("KEMBALI KE BERANDA", style: TextStyle(fontWeight: FontWeight.w900, color: ReceiptPage.primaryGreen)),
        ),
      ],
    );
  }

  Widget _receiptDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: ReceiptPage.textLight, fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: ReceiptPage.textDark)),
        ],
      ),
    );
  }

  Widget _totalDetailRow(String label, String value, {bool isBold = false, bool isDiscount = false, Color color = ReceiptPage.textDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: isBold ? 14 : 12, fontWeight: isBold ? FontWeight.w900 : FontWeight.w600, color: color)),
        Text(
          value, 
          style: TextStyle(
            fontSize: isBold ? 22 : 12, 
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w800, 
            color: isDiscount ? Colors.red : color,
          ),
        ),
      ],
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final String name, qty, price;
  final String? note;
  final NumberFormat currency;
  
  const _OrderItemRow({required this.name, required this.qty, required this.price, this.note, required this.currency});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${qty}x", style: const TextStyle(fontWeight: FontWeight.w900, color: ReceiptPage.primaryGreen, fontSize: 13)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: ReceiptPage.textDark)),
                if (note != null && note!.isNotEmpty)
                  Text("($note)", style: const TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: ReceiptPage.textDark)),
        ],
      ),
    );
  }
}