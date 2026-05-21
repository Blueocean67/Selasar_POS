import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:selasar_pos/provider/promo_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- IMPORT MANAGER PUSAT ---
import 'package:selasar_pos/main.dart';

class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);

  final supabase = Supabase.instance.client;

  String searchQuery = "";
  String selectedCategory = "Semua";

  final List<String> categories = [
    "Semua",
    "Kopi",
    "Non-Kopi",
    "Food",
    "Snack"
  ];

  final Map<String, String> localAssetImages = {
    "Aceh Gayo V60": "assets/images/acehgayov60.png",
    "Amerikano": "assets/images/americano.jpg",
    "Signature Selasar Latte": "assets/images/Caramellatte.jpg",
    "Kopi Gula Aren": "assets/images/kopigulaaren.webp",
    "Matcha Latte": "assets/images/matchalatte.webp",
    "Lemon Tea": "assets/images/lemontea.jpg",
    "Jus Strawberry": "assets/images/Jusstrawberry.jpg",
    "Almonds Chocolate": "assets/images/AlmondsChocolate.jpg",
    "Milk Shake": "assets/images/milkshake.jpg",
    "Mie Bangladesh": "assets/images/Miebangladesh.jpg",
    "Nasi Goreng": "assets/images/nasigoreng.jpg",
    "Ayam Pop": "assets/images/ayampop.webp",
    "Ayam Sambal Geprek": "assets/images/ayamsambalgeprek.jpg",
    "Nasi Beef Teriyaki": "assets/images/nasibeefteriyaki.jpg",
    "Spaghetti Bologness": "assets/images/spagettibolognes.jpg",
    "Roti Bakar": "assets/images/RotiBakar.jpg",
    "Donat": "assets/images/donat.jpg",
    "Cheesecake": "assets/images/cheesecake.jpg",
    "Cookies": "assets/images/cookies.jpg",
    "Burger": "assets/images/burger.jpg",
  };

  // State pengaman internal melacak ID transaksi agar tidak memotong stok berkali-kali
  final Set<String> _processedLocalOrderIds = {};

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        final provider = context.read<PromoProvider>();
        provider.listenToStockChanges();
        _syncStockFromLocalHistory();
      }
    });
  }

  // =========================================================================
  // CORE ENGINE SINKRONISASI: POTONG LOKAL INSTANT + BACKGROUND UPDATE DB
  // =========================================================================
  void _syncStockFromLocalHistory() {
    final historyManager = context.read<OrderHistoryManager>();
    final promoProvider = context.read<PromoProvider>();

    for (var order in historyManager.allOrders) {
      final String orderId = order['id']?.toString() ?? '';
      if (orderId.isEmpty || _processedLocalOrderIds.contains(orderId)) continue;

      final dynamic rawItems = order['menu_items'] ?? order['items'];
      if (rawItems is List) {
        for (final item in rawItems) {
          final String menuName = (item['name'] ?? item['menu_name'] ?? '').toString();
          final int qtyBought = ((item['qty'] ?? item['quantity'] ?? 1) as num).toInt();

          if (menuName.isNotEmpty) {
            final existingMenu = promoProvider.allMenusWithStock.firstWhere(
              (element) => element['name'].toString().trim().toLowerCase() == menuName.trim().toLowerCase(),
              orElse: () => {},
            );

            if (existingMenu.isNotEmpty) {
              final String id = existingMenu['id'].toString();
              int currentStock = ((existingMenu['stock'] ?? 20) as num).toInt();
              if (currentStock == 9999 || currentStock < 0) currentStock = 20;

              int updatedStock = (currentStock - qtyBought).clamp(0, 99999);
              
              // 1. UPDATE STATE MANAGEMENT LOKAL SECARA INSTANT
              promoProvider.updateStock(id, updatedStock);

              // 2. UPDATE REMOTE DATABASE (Supabase) DI BACKGROUND TANPA PERLU AWAIT DI BUILD
              unawaited(
                supabase
                    .from('menus')
                    .update({'stock': updatedStock})
                    .eq('id', id)
                    .then((_) => debugPrint("Stok $menuName berhasil dipotong di Supabase"))
                    .catchError((e) => debugPrint("Gagal update stok ke Supabase: $e"))
              );
            }
          }
        }
      }
      _processedLocalOrderIds.add(orderId);
    }
  }

  void _showRestockDialog(BuildContext context, String id, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            "Stok $name Habis!",
            style: const TextStyle(fontWeight: FontWeight.bold, color: primaryGreen),
          ),
          content: const Text(
            "Apakah Anda ingin mengisi kembali (Restock) produk ini ke batas default (20 item) sekarang?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Belum Restock", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                try {
                  await supabase.from('menus').update({'stock': 20}).eq('id', id);
                } catch (_) {}
                if (mounted) {
                  context.read<PromoProvider>().updateStock(id, 20);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text("Ya, Sudah Restock (20)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Daftarkan listener utama untuk memantau simulasi pesanan otomatis masuk
    context.watch<OrderHistoryManager>();
    
    // Jalankan sinkronisasi pemotongan stok otomatis ke database
    _syncStockFromLocalHistory();

    final promoProvider = context.watch<PromoProvider>();
    final List<Map<String, dynamic>> allItems = promoProvider.allMenusWithStock;

    final filteredMenu = allItems.where((item) {
      final matchesSearch = item['name']
          .toString()
          .toLowerCase()
          .contains(searchQuery.toLowerCase());

      final matchesCat = selectedCategory == "Semua" ||
          item['category'].toString().toLowerCase() == selectedCategory.toLowerCase();

      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: bgSurface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: _buildSearchField(),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildCategoryChips(),
            ),
            filteredMenu.isEmpty
                ? const SliverFillRemaining(
                    child: Center(child: Text("Menu tidak ditemukan", style: TextStyle(color: Colors.grey))),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildStockCard(filteredMenu[index]),
                        childCount: filteredMenu.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text(
        "KONTROL MANAJEMEN STOK",
        style: TextStyle(
          color: primaryGreen,
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 1.5,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: "Cari produk di Selasar...",
        prefixIcon: const Icon(Icons.search_rounded, color: primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          bool isSelected = selectedCategory == categories[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(categories[index]),
              selected: isSelected,
              onSelected: (val) {
                setState(() {
                  selectedCategory = categories[index];
                });
              },
              selectedColor: primaryGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item) {
    int currentStock = item['stock'] ?? 0;
    if (currentStock == 9999 || currentStock < 0) currentStock = 20;

    bool isAvailable = currentStock > 0;
    String id = item['id'].toString();
    String name = item['name'] ?? '';
    String itemImage = item['image']?.toString() ?? '';

    String finalImagePath = itemImage;
    bool isNetworkImage = finalImagePath.startsWith('http') || finalImagePath.startsWith('https');

    if (!isNetworkImage) {
      if (localAssetImages.containsKey(name)) {
        finalImagePath = localAssetImages[name]!;
      } else if (finalImagePath.isEmpty) {
        finalImagePath = 'assets/images/americano.jpg';
      }
    }

    String stockStatusLabel = "OUT OF STOCK";
    Color statusColor = Colors.red;

    if (currentStock > 5) {
      stockStatusLabel = "SISA: $currentStock";
      statusColor = Colors.green;
    } else if (currentStock >= 1 && currentStock <= 5) {
      stockStatusLabel = "STOK MENIPIS: $currentStock";
      statusColor = Colors.orange;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.01), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: ColorFiltered(
              colorFilter: isAvailable
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: isNetworkImage
                  ? Image.network(finalImagePath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildErrorImagePlaceholder())
                  : Image.asset(finalImagePath, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (c, e, s) => _buildErrorImagePlaceholder()),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: Text(
                    stockStatusLabel,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor, letterSpacing: 0.3),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: currentStock > 0
                    ? () async {
                        int updatedStock = currentStock - 1;
                        try {
                          await supabase.from('menus').update({'stock': updatedStock}).eq('id', id);
                        } catch (_) {}
                        if (mounted) {
                          context.read<PromoProvider>().updateStock(id, updatedStock);
                        }
                        if (updatedStock == 0 && mounted) {
                          _showRestockDialog(context, id, name);
                        }
                      }
                    : null,
                icon: const Icon(Icons.remove_circle_outline, color: primaryGreen, size: 22),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text("$currentStock", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              ),
              IconButton(
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
                onPressed: () async {
                  int updatedStock = currentStock + 1;
                  try {
                    await supabase.from('menus').update({'stock': updatedStock}).eq('id', id);
                  } catch (_) {}
                  if (mounted) {
                    context.read<PromoProvider>().updateStock(id, updatedStock);
                  }
                },
                icon: const Icon(Icons.add_circle, color: primaryGreen, size: 22),
              ),
            ],
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: isAvailable,
              activeColor: primaryGreen,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onChanged: (val) async {
                int updatedStock = val ? 20 : 0;
                try {
                  await supabase.from('menus').update({'stock': updatedStock}).eq('id', id);
                } catch (_) {}
                if (mounted) {
                  context.read<PromoProvider>().updateStock(id, updatedStock);
                }
                if (!val && mounted) {
                  _showRestockDialog(context, id, name);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorImagePlaceholder() {
    return Container(
      width: 60,
      height: 60,
      color: Colors.grey[100],
      child: const Icon(Icons.fastfood_rounded, color: Colors.grey, size: 20),
    );
  }
}