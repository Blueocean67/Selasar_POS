import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
// FIX PATH IMPORT: Disesuaikan dengan struktur folder asli lib/provider/ Anda
import 'package:selasar_pos/provider/promo_provider.dart';

class OrderSummaryPage extends StatefulWidget {
  const OrderSummaryPage({super.key});

  @override
  State<OrderSummaryPage> createState() => _OrderSummaryPageState();
}

class _OrderSummaryPageState extends State<OrderSummaryPage> {
  static const Color olive = Color(0xFF4A5D3F); 
  static const Color bg = Color(0xFFF8F9F2);    
  static const Color textDark = Color(0xFF2D3329);

  String selectedPaymentMethod = "Tunai"; 
  final TextEditingController _cashController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  
  String? selectedBank;
  final List<String> banks = ["Bank Mandiri", "BCA", "BRI", "BNI", "Bank CIMB Niaga"];
  double cashReturned = 0;

  // State utama penampung data pesanan yang aktif
  Map<String, dynamic> _activeOrderArgs = {};
  bool _isDataInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Mengambil data rute asli dari MenuPage secara realtime saat halaman dimuat
    if (!_isDataInitialized) {
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // Melakukan deep copy data agar tidak merusak state global sebelum diselesaikan
        _activeOrderArgs = Map<String, dynamic>.from(args);
        if (_activeOrderArgs['items'] != null) {
          _activeOrderArgs['items'] = List<Map<String, dynamic>>.from(
            (_activeOrderArgs['items'] as List).map((item) {
              final mappedItem = Map<String, dynamic>.from(item as Map);
              // HARMONISASI KUNCI DATA: Memastikan 'quantity' dan 'qty' bernilai sama agar sinkron
              int totalQty = int.tryParse('${mappedItem['quantity'] ?? mappedItem['qty'] ?? 1}') ?? 1;
              mappedItem['quantity'] = totalQty;
              mappedItem['qty'] = totalQty;
              return mappedItem;
            }),
          );
        }
      }
      _isDataInitialized = true;
      _calculateChange(_getComputedTotal());
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _cardNumberController.dispose();
    super.dispose();
  }

  // Aksi Tambah Qty Realtime dengan Validasi Stok Ketat dari PromoProvider
  void _increaseItemQty(int index) {
    final promoProvider = context.read<PromoProvider>();
    final List<dynamic> items = _activeOrderArgs['items'] ?? [];
    final item = items[index] as Map<String, dynamic>;
    final String menuId = item['id'].toString();

    // Ambil batas stok riil dari provider pusat manajemen stok
    final providerItem = promoProvider.allMenusWithStock.firstWhere(
      (e) => e['id'].toString() == menuId,
      orElse: () => {},
    );
    int liveStock = providerItem['stock'] ?? item['stock'] ?? 20;
    if (liveStock == 9999) liveStock = 20;

    setState(() {
      int currentQty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 0}') ?? 0;
      
      if (currentQty >= liveStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Batas stok maksimum tercapai ($liveStock unit).")),
        );
        return;
      }

      currentQty++;
      item['quantity'] = currentQty;
      item['qty'] = currentQty;
      
      _reapplyPromoIfActive();
      _calculateChange(_getComputedTotal());
    });
  }

  // Aksi Kurang / Hapus Item Realtime
  void _decreaseItemQty(int index) {
    setState(() {
      final List<dynamic> items = _activeOrderArgs['items'] ?? [];
      final item = items[index] as Map<String, dynamic>;
      int currentQty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 0}') ?? 0;
      
      if (currentQty > 1) {
        currentQty--;
        item['quantity'] = currentQty;
        item['qty'] = currentQty;
      } else {
        items.removeAt(index);
      }
      
      _reapplyPromoIfActive();
      _calculateChange(_getComputedTotal());
    });
  }

  // Kalkulasi ulang nilai diskon promo jika keranjang belanja dimanipulasi di summary page
  void _reapplyPromoIfActive() {
    final provider = context.read<PromoProvider>();
    if (provider.currentAppliedPromo != null) {
      double subtotal = _getComputedSubtotal();
      List<Map<String, dynamic>> itemConverted = (_activeOrderArgs['items'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      provider.applyPromoByCode(provider.currentAppliedPromo!.code, subtotal.toInt(), itemConverted);
      _activeOrderArgs['discount'] = provider.calculateDiscount(subtotal.toInt(), itemConverted).toDouble();
    } else {
      _activeOrderArgs['discount'] = 0.0;
    }
  }

  double _getComputedSubtotal() {
    double subtotal = 0.0;
    final List<dynamic> items = _activeOrderArgs['items'] ?? [];

    for (var item in items) {
      if (item is Map) {
        final int qty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1;
        final double price = double.tryParse('${item['price'] ?? 0}') ?? 0;
        subtotal += qty * price;
      }
    }
    return subtotal;
  }

  double _getComputedTotal() {
    final double subtotal = _getComputedSubtotal();
    final double discount = ((_activeOrderArgs['discount'] ?? 0.0) as num).toDouble();
    final double total = subtotal - discount;
    return total < 0 ? 0 : total;
  }

  void _calculateChange(double totalPayable) {
    final cashAmount = double.tryParse(_cashController.text) ?? 0;
    setState(() {
      if (cashAmount >= totalPayable) {
        cashReturned = cashAmount - totalPayable;
      } else {
        cashReturned = 0;
      }
    });
  }

  // OTOMASI HUBUNGAN DATABASE DAN STATE KETIKA SUKSES BAYAR (REALTIME & UPDATE OMSET)
  void _processPayment(Map<String, dynamic> orderArgs, double total) async {
    final List<dynamic> itemsList = orderArgs['items'] ?? [];
    if (itemsList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tidak ada produk untuk diproses!"), backgroundColor: Colors.red),
      );
      return;
    }

    if (selectedPaymentMethod == "Tunai") {
      final cashAmount = double.tryParse(_cashController.text) ?? 0;
      if (cashAmount < total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Uang tunai yang dimasukkan kurang!"), backgroundColor: Colors.red),
        );
        return;
      }
    }

    if (selectedPaymentMethod == "Debit") {
      if (selectedBank == null || _cardNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pilih Bank dan isi Nomor Kartu Debit!"), backgroundColor: Colors.red),
        );
        return;
      }
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: olive)),
    );

    // Generate ringkasan product string untuk tracking report top-product di database
    String productSummary = itemsList.map((e) {
      String name = e['name'] ?? 'Menu';
      int qty = int.tryParse('${e['quantity'] ?? e['qty'] ?? 1}') ?? 1;
      return "$name ($qty)";
    }).join(", ");

    int totalItemsCount = itemsList.fold(0, (sum, item) {
      int qty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1;
      return sum + qty;
    });

    try {
      final supabase = Supabase.instance.client;
      final String paymentString = selectedPaymentMethod == "Debit" ? "Debit ($selectedBank)" : selectedPaymentMethod;
      final staffName = supabase.auth.currentUser?.userMetadata?['full_name'] ?? 'Staff Selasar';

      // 1. Simpan ke tabel 'orders' untuk order tracker tracking kitchen
      await supabase.from('orders').insert({
        'customer_name': orderArgs['customer_name'] ?? 'Pelanggan',
        'table_number': orderArgs['table_number'] ?? '-',
        'total_price': total.toInt(),
        'payment_method': paymentString,
        'status': 'Diproses', 
        'items': itemsList,  
        'created_at': DateTime.now().toIso8601String(),
      });

      // 2. Simpan Data Transaksi Resmi ke Tabel 'transactions' (Konsistensi Laporan Eksekutif PDF)
      await supabase.from('transactions').insert({
        'total_price': total.toInt(),
        'payment_status': 'SUCCESS',
        'cashier_name': staffName,
        'items_count': totalItemsCount,
        'product_summary': productSummary,
        'user_id': supabase.auth.currentUser?.id,
        'created_at': DateTime.now().toIso8601String(),
      });

      // 3. Sinkronisasi Pengurangan Stok Otomatis Secara Realtime ke Tabel 'menus'
      for (var item in itemsList) {
        if (item is Map) {
          final String? menuId = item['id']?.toString() ?? item['menu_id']?.toString();
          final int qty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 0}') ?? 0;

          if (menuId != null && qty > 0) {
            final currentMenuResponse = await supabase.from('menus').select('stock').eq('id', menuId).maybeSingle();
            if (currentMenuResponse != null && currentMenuResponse['stock'] != null) {
              int currentStock = (currentMenuResponse['stock'] as num).toInt();
              int updatedStock = currentStock - qty;
              if (updatedStock < 0) updatedStock = 0; 

              await supabase.from('menus').update({'stock': updatedStock}).eq('id', menuId);
            }
          }
        }
      }

      // 4. Update PromoProvider local cache management agar sinkronisasi dashboard & stok langsung menyebar realtime
      if (mounted) {
        final List<Map<String, dynamic>> cartItemsConverted = itemsList
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        await context.read<PromoProvider>().reduceStockAfterOrder(cartItemsConverted);
      }

    } catch (e) {
      debugPrint("Sistem POS Automasi Database Error: $e");
    }

    if (!mounted) return;
    Navigator.pop(context); // Tutup loading dialog

    if (selectedPaymentMethod == "QRIS") {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Scan QRIS Selasar", style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.network(
                'https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=SelasarPOS_DynamicQR',
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
              const SizedBox(height: 12),
              Text(
                "Total Tagihan: Rp ${total.toInt()}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: olive, fontSize: 16),
              ),
              const SizedBox(height: 4),
              const Text("Silakan scan menggunakan e-wallet atau m-banking", style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext),
                style: ElevatedButton.styleFrom(backgroundColor: olive, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text("DANA DITERIMA (SUKSES)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 10)
          ],
        )
      );
    }

    if (!mounted) return;

    // Menyiapkan payload receipt data untuk diteruskan ke payment_success
    final Map<String, dynamic> successArguments = {
      'customer_name': orderArgs['customer_name'] ?? 'Pelanggan',
      'table_number': orderArgs['table_number'] ?? '-',
      'subtotal': _getComputedSubtotal(),
      'discount': ((_activeOrderArgs['discount'] ?? 0.0) as num).toDouble(),
      'total': total,
      'payment_method': selectedPaymentMethod == "Debit" ? "Debit ($selectedBank)" : selectedPaymentMethod,
      'change': selectedPaymentMethod == "Tunai" ? cashReturned : 0.0,
      'items': itemsList,
    };

    // Bersihkan data state sebelum berpindah rute agar transaksi selanjutnya bersih
    setState(() {
      _activeOrderArgs['items'] = [];
    });

    Navigator.pushReplacementNamed(
      context,
      '/payment_success',
      arguments: successArguments,
    );
  }

  @override
  Widget build(BuildContext context) {
    final String customerName = _activeOrderArgs['customer_name'] ?? "Pelanggan POS";
    final String tableNumber = _activeOrderArgs['table_number'] ?? "00";
    final List<dynamic> items = _activeOrderArgs['items'] ?? []; 
    
    // Auto-recalculation data finansial
    final double subtotal = _getComputedSubtotal();
    
    // =========================================================================
    // TEMPAT PERBAIKAN: Menyisipkan pemanggilan PromoProvider secara bersih & legal
    // =========================================================================
    final promoProvider = Provider.of<PromoProvider>(context);
    final List<Map<String, dynamic>> cartItems = items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    final double discount = promoProvider.calculateDiscount(
      subtotal.toInt(),
      cartItems,
    ).toDouble();
    
    // Masukkan hasil hitung ulang otomatis diskon ke state penampung utama
    _activeOrderArgs['discount'] = discount;
    final double total = subtotal - discount < 0 ? 0 : subtotal - discount;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: const Text("RINGKASAN PESANAN", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("NAMA PEMESAN", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(customerName.toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(color: olive.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
                    child: Text("Meja $tableNumber", style: const TextStyle(color: olive, fontWeight: FontWeight.bold, fontSize: 14)),
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 25),
            const Text("Daftar Produk Pesanan", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 12),

            items.isEmpty 
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: Text("Belum ada produk dipilih", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index] as Map<String, dynamic>;
                    final String name = item['name'] ?? "Menu";
                    final int qty = int.tryParse('${item['quantity'] ?? item['qty'] ?? 1}') ?? 1;
                    final double price = double.tryParse('${item['price'] ?? 0}') ?? 0;
                    final String image = item['image'] ?? item['image_url'] ?? '';
                    final String? note = item['note'];

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: image.startsWith('http') || image.startsWith('https')
                                ? Image.network(image, width: 65, height: 65, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorImg())
                                : image.isNotEmpty 
                                    ? Image.asset(image, width: 65, height: 65, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _errorImg())
                                    : _errorImg(),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                                if (note != null && note.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Text("Note: $note", style: const TextStyle(color: Color(0xFFD4A373), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Tombol Aksi Minus / Hapus Item Ringkas
                                    InkWell(
                                      onTap: () => _decreaseItemQty(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                        child: Icon(qty > 1 ? Icons.remove : Icons.delete_outline, size: 14, color: Colors.grey),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Text("$qty", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark)),
                                    ),
                                    // Tombol Aksi Plus Ringkas
                                    InkWell(
                                      onTap: () => _increaseItemQty(index),
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(4)),
                                        child: const Icon(Icons.add, size: 14, color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text("x Rp ${price.toInt()}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Text("Rp ${(price * qty).toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: textDark)),
                        ],
                      ),
                    );
                  },
                ),

            const Divider(height: 30),
            
            _buildAmountRow("Subtotal", subtotal),
            if (discount > 0) _buildAmountRow("Diskon Promo", -discount, isDiscount: true),
            const SizedBox(height: 8),
            _buildAmountRow("Total Pembayaran", total, isTotal: true),

            const Divider(height: 40),
            const Text("Metode Pembayaran", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textDark)),
            const SizedBox(height: 15),

            Row(
              children: [
                _buildPaymentMethodCard(Icons.money, "Tunai"),
                const SizedBox(width: 10),
                _buildPaymentMethodCard(Icons.qr_code_scanner, "QRIS"),
                const SizedBox(width: 10),
                _buildPaymentMethodCard(Icons.credit_card, "Debit"),
              ],
            ),

            const SizedBox(height: 25),

            if (selectedPaymentMethod == "Tunai") ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("INPUT TUNAI (Rp)", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _cashController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => _calculateChange(total),
                      decoration: InputDecoration(
                        hintText: "Masukkan jumlah uang cash",
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Kembalian", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        Text("Rp ${cashReturned.toInt()}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: olive)),
                      ],
                    ),
                  ],
                ),
              ),
            ] else if (selectedPaymentMethod == "Debit") ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("PILIH BANK", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedBank,
                      hint: const Text("Pilih Bank Penerbit Kartu"),
                      items: banks.map((bank) {
                        return DropdownMenuItem(value: bank, child: Text(bank));
                      }).toList(),
                      onChanged: (val) => setState(() => selectedBank = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    const Text("NOMOR KARTU DEBIT", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _cardNumberController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: "Contoh: 4563 8812 9901 XXXX",
                        filled: true,
                        fillColor: bg,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (selectedPaymentMethod == "QRIS") ...[
              _buildInfoContainer("Klik SELESAIKAN TRANSAKSI untuk memunculkan pop-up kode QRIS Dinarasiasi POS secara otomatis."),
            ],

            const SizedBox(height: 40),
            
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: items.isEmpty ? null : () => _processPayment(_activeOrderArgs, total),
                style: ElevatedButton.styleFrom(
                  backgroundColor: olive,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 0,
                ),
                child: const Text("SELESAIKAN TRANSAKSI", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _errorImg() => Container(width: 65, height: 65, color: Colors.grey[200], child: const Icon(Icons.fastfood, color: Colors.grey));

  Widget _buildAmountRow(String label, double amount, {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: isTotal ? 16 : 14, fontWeight: isTotal ? FontWeight.bold : FontWeight.normal, color: isTotal ? textDark : Colors.grey)),
          Text(
            isDiscount ? "- Rp ${amount.abs().toInt()}" : "Rp ${amount.toInt()}",
            style: TextStyle(
              fontSize: isTotal ? 20 : 15,
              fontWeight: FontWeight.bold,
              color: isTotal ? olive : (isDiscount ? Colors.red : textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(IconData icon, String method) {
    bool isSelected = selectedPaymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            selectedPaymentMethod = method;
            if (method != "Tunai") _cashController.clear();
            if (method != "Debit") {
              _cardNumberController.clear();
              selectedBank = null;
            }
            cashReturned = 0;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? olive : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isSelected ? olive : Colors.grey.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? Colors.white : olive, size: 24),
              const SizedBox(height: 8),
              Text(method, style: TextStyle(color: isSelected ? Colors.white : textDark, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoContainer(String info) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: olive.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: olive, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(info, style: const TextStyle(fontSize: 12, color: Colors.black54, height: 1.4))),
        ],
      ),
    );
  }
}