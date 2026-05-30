import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==========================================
// ENUM STATUS PROMO
// ==========================================
enum PromoStatus {
  scheduled,
  active,
  expired,
}

// ==========================================
// MODEL DATA PROMO
// ==========================================
class PromoModel {
  final String id;
  final String code;
  final String description;
  final double discountPercentage; 
  final int maxDiscount;      
  final int minTransaction;   
  bool isActive;
  final DateTime startDate;
  final DateTime endDate;
  
  final String scope; // 'global', 'category', 'product'
  final List<String> targetProductIds;
  final List<String> targetCategories;

  PromoModel({
    required this.id,
    required this.code,
    required this.description,
    required this.discountPercentage,
    this.maxDiscount = 0,
    this.minTransaction = 0,
    this.isActive = true,
    required this.startDate,
    required this.endDate,
    this.scope = 'global',
    this.targetProductIds = const [],
    this.targetCategories = const [],
  });

  PromoStatus get status {
    final now = DateTime.now();
    if (now.isBefore(startDate)) {
      return PromoStatus.scheduled;
    } else if (now.isAfter(endDate)) {
      return PromoStatus.expired;
    } else {
      return PromoStatus.active;
    }
  }

  bool get isCurrentlyValid {
    return isActive && status == PromoStatus.active;
  }

  factory PromoModel.fromMap(Map<String, dynamic> map) {
    List<String> parseList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value.map((e) => e.toString()).toList();
      if (value is String) {
        if (value.startsWith('[') && value.endsWith(']')) {
          return value.replaceAll('[', '').replaceAll(']', '').split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
        return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }
      return [];
    }

    return PromoModel(
      id: map['id'].toString(),
      code: map['code'] ?? '',
      description: map['description'] ?? '',
      discountPercentage: (map['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      maxDiscount: (map['max_discount'] as num?)?.toInt() ?? 0,
      minTransaction: (map['min_transaction'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] ?? false,
      startDate: map['start_date'] != null 
          ? DateTime.parse(map['start_date']).toLocal() 
          : DateTime.now(),
      endDate: map['end_date'] != null 
          ? DateTime.parse(map['end_date']).toLocal() 
          : DateTime.now().add(const Duration(days: 1)),
      scope: map['scope'] ?? 'global',
      targetProductIds: parseList(map['target_product_ids']),
      targetCategories: parseList(map['target_categories']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'code': code,
      'description': description,
      'discount_percentage': discountPercentage,
      'max_discount': maxDiscount,
      'min_transaction': minTransaction,
      'is_active': isActive,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'scope': scope,
      'target_product_ids': targetProductIds,
      'target_categories': targetCategories,
    };
  }
}

// ==========================================
// PROMO PROVIDER (Otak Manajemen & Transaksi Otomatis)
// ==========================================
class PromoProvider with ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  List<PromoModel> _promos = [];
  PromoModel? _currentAppliedPromo; 
  bool _isLoading = false;

  List<PromoModel> get promos => _promos;
  List<PromoModel> get activePromos => _promos.where((p) => p.isCurrentlyValid).toList(); 
  List<PromoModel> get scheduledPromos => _promos.where((p) => p.status == PromoStatus.scheduled).toList();
  List<PromoModel> get expiredPromos => _promos.where((p) => p.status == PromoStatus.expired).toList();
  PromoModel? get currentAppliedPromo => _currentAppliedPromo; 
  bool get isLoading => _isLoading;

  PromoProvider() {
    _promos = [
      PromoModel(
        id: "dummy_kopi_1",
        code: "KOPIHEMAT",
        description: "Diskon 20% khusus item dalam kategori Kopi, Max Rp 10.000",
        discountPercentage: 20.0,
        maxDiscount: 10000,
        minTransaction: 0,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 7)),
        scope: "category",
        targetCategories: ["Kopi"],
      ),
      PromoModel(
        id: "dummy_kopi_2",
        code: "COFFEEADDICT",
        description: "Diskon besar 30% khusus Kopi, Max Rp 15.000",
        discountPercentage: 30.0,
        maxDiscount: 15000,
        minTransaction: 20000,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 5)),
        scope: "category",
        targetCategories: ["Kopi"],
      ),
      PromoModel(
        id: "dummy_global",
        code: "SELASARKAN",
        description: "Potongan global 10% untuk semua item di keranjang",
        discountPercentage: 10.0,
        maxDiscount: 0,
        minTransaction: 0,
        isActive: true,
        startDate: DateTime.now().subtract(const Duration(days: 1)),
        endDate: DateTime.now().add(const Duration(days: 10)),
        scope: "global",
      ),
    ];

    _initRealtimePromoListener();
  }

  void _initRealtimePromoListener() {
    _supabase.from('promos').stream(primaryKey: ['id']).listen((data) {
      final dbItems = data.map((item) => PromoModel.fromMap(item)).toList();
      
      final Map<String, PromoModel> uniquePromos = {};
      for (var p in _promos) {
        if (p.id.startsWith("dummy_")) uniquePromos[p.code] = p;
      }
      for (var p in dbItems) {
        uniquePromos[p.code] = p;
      }

      _promos = uniquePromos.values.toList();
      
      if (_currentAppliedPromo != null) {
        final index = _promos.indexWhere((p) => p.id == _currentAppliedPromo!.id);
        if (index == -1 || !_promos[index].isCurrentlyValid) {
          _currentAppliedPromo = null; 
        } else {
          _currentAppliedPromo = _promos[index]; 
        }
      }
      notifyListeners();
    });
  }

  Future<void> fetchPromosFromDatabase() async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase.from('promos').select().order('id', ascending: false);
      final dbItems = List<Map<String, dynamic>>.from(response).map((item) => PromoModel.fromMap(item)).toList();
      
      final Map<String, PromoModel> uniquePromos = {};
      for (var p in _promos) {
        if (p.id.startsWith("dummy_")) uniquePromos[p.code] = p;
      }
      for (var p in dbItems) {
        uniquePromos[p.code] = p;
      }
      _promos = uniquePromos.values.toList();
    } catch (e) {
      debugPrint("Gagal mengambil data promo: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPromo({
    required String code,
    required String description,
    required double discountPercentage,
    int maxDiscount = 0,
    int minTransaction = 0,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
    String scope = 'global',
    List<String> targetProductIds = const [],
    List<String> targetCategories = const [],
  }) async {
    if (code.trim().isEmpty) return false;
    if (discountPercentage <= 0 || discountPercentage > 100) return false;
    
    final finalStartDate = startDate ?? DateTime.now();
    final finalEndDate = endDate ?? finalStartDate.add(const Duration(days: 1));
    if (finalEndDate.isBefore(finalStartDate)) return false;

    try {
      await _supabase.from('promos').insert({
        'code': code.toUpperCase().trim(),
        'description': description,
        'discount_percentage': discountPercentage,
        'max_discount': maxDiscount,
        'min_transaction': minTransaction,
        'is_active': isActive,
        'start_date': finalStartDate.toIso8601String(),
        'end_date': finalEndDate.toIso8601String(),
        'scope': scope,
        'target_product_ids': targetProductIds,
        'target_categories': targetCategories,
      });
      return true;
    } catch (e) {
      debugPrint("Gagal tambah promo: $e");
      return false;
    }
  }

  Future<bool> editPromo({
    required String id,
    required String code,
    required String description,
    required double discountPercentage,
    int maxDiscount = 0,
    int minTransaction = 0,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    String? scope,
    List<String>? targetProductIds,
    List<String>? targetCategories,
  }) async {
    if (code.trim().isEmpty) return false;
    if (discountPercentage <= 0 || discountPercentage > 100) return false;

    final index = _promos.indexWhere((p) => p.id == id);
    if (index == -1) return false;

    final finalStartDate = startDate ?? _promos[index].startDate;
    final finalEndDate = endDate ?? _promos[index].endDate;
    final finalIsActive = isActive ?? _promos[index].isActive;

    if (finalEndDate.isBefore(finalStartDate)) return false;

    if (id.startsWith("dummy_")) {
      _promos[index] = PromoModel(
        id: id,
        code: code.toUpperCase().trim(),
        description: description,
        discountPercentage: discountPercentage,
        maxDiscount: maxDiscount,
        minTransaction: minTransaction,
        isActive: finalIsActive,
        startDate: finalStartDate,
        endDate: finalEndDate,
        scope: scope ?? _promos[index].scope,
        targetProductIds: targetProductIds ?? _promos[index].targetProductIds,
        targetCategories: targetCategories ?? _promos[index].targetCategories,
      );
      notifyListeners();
      return true;
    }

    try {
      await _supabase.from('promos').update({
        'code': code.toUpperCase().trim(),
        'description': description,
        'discount_percentage': discountPercentage,
        'max_discount': maxDiscount,
        'min_transaction': minTransaction,
        'is_active': finalIsActive,
        'start_date': finalStartDate.toIso8601String(),
        'end_date': finalEndDate.toIso8601String(),
        'scope': scope ?? _promos[index].scope,
        'target_product_ids': targetProductIds ?? _promos[index].targetProductIds,
        'target_categories': targetCategories ?? _promos[index].targetCategories,
      }).eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Gagal edit promo: $e");
      return false;
    }
  }

  Future<void> togglePromoStatus(String id) async {
    final index = _promos.indexWhere((p) => p.id == id);
    if (index == -1) return;

    _promos[index].isActive = !_promos[index].isActive;
    notifyListeners();

    if (id.startsWith("dummy_")) return;

    try {
      await _supabase.from('promos').update({'is_active': _promos[index].isActive}).eq('id', id);
    } catch (e) {
      debugPrint("Gagal update status: $e");
    }
  }

  Future<bool> deletePromo(String id) async {
    _promos.removeWhere((p) => p.id == id);
    notifyListeners();

    if (id.startsWith("dummy_")) return true;

    try {
      await _supabase.from('promos').delete().eq('id', id);
      return true;
    } catch (e) {
      debugPrint("Gagal menghapus promo: $e");
      return false;
    }
  }

  String? applyPromoByCode(String code, int currentTransactionTotal, List<Map<String, dynamic>> cartItems) {
    final cleanCode = code.toUpperCase().trim();
    
    PromoModel promo;
    try {
      promo = _promos.firstWhere(
        (p) => p.code.toUpperCase() == cleanCode,
      );
    } catch (_) {
      return "Kode promo tidak ditemukan.";
    }

    if (!promo.isActive) return "Promo ini sudah dinonaktifkan oleh toko.";
    if (promo.status == PromoStatus.scheduled) return "Promo belum dimulai.";
    if (promo.status == PromoStatus.expired) return "Promo ini telah kadaluwarsa.";
    if (currentTransactionTotal < promo.minTransaction) {
      return "Minimal transaksi Rp ${promo.minTransaction} untuk promo ini.";
    }

    if (promo.scope == 'product') {
      bool hasValidProduct = cartItems.any((item) {
        String itemId = item['id'].toString();
        return promo.targetProductIds.contains(itemId);
      });
      if (!hasValidProduct) return "Produk di keranjang tidak termasuk promo ini.";
    } 
    else if (promo.scope == 'category') { 
      bool hasValidCategory = cartItems.any((item) {
        String itemCat = (item['category'] ?? '').toString().toLowerCase().trim();
        return promo.targetCategories.any((c) => c.toLowerCase().trim() == itemCat);
      });
      if (!hasValidCategory) return "Kategori produk tidak sesuai.";
    }

    _currentAppliedPromo = promo;
    notifyListeners();
    return null; 
  }

  int calculateDiscount(int currentTransactionTotal, List<Map<String, dynamic>> cartItems) {
    if (_currentAppliedPromo == null || !_currentAppliedPromo!.isCurrentlyValid) return 0;

    double calculatedDiscount = 0.0;
    final promo = _currentAppliedPromo!;

    if (promo.scope == 'global') {
      calculatedDiscount = currentTransactionTotal * (promo.discountPercentage / 100);
    } else {
      for (var item in cartItems) {
        String itemId = item['id'].toString();
        String itemCategory = (item['category'] ?? '').toString().toLowerCase().trim(); 
        int price = int.tryParse(item['price'].toString()) ?? 0;
        int qty = int.tryParse(item['quantity'].toString()) ?? int.tryParse(item['qty'].toString()) ?? 1;
        int itemTotalBilling = price * qty;

        if (promo.scope == 'product' && promo.targetProductIds.contains(itemId)) {
          calculatedDiscount += itemTotalBilling * (promo.discountPercentage / 100);
        } else if (promo.scope == 'category' && promo.targetCategories.any((c) => c.toLowerCase().trim() == itemCategory)) {
          calculatedDiscount += itemTotalBilling * (promo.discountPercentage / 100);
        }
      }
    }

    int finalDiscountAmount = calculatedDiscount.round();
    if (promo.maxDiscount > 0 && finalDiscountAmount > promo.maxDiscount) {
      finalDiscountAmount = promo.maxDiscount;
    }

    return finalDiscountAmount > currentTransactionTotal ? currentTransactionTotal : finalDiscountAmount;
  }

  void removeCurrentPromo() {
    _currentAppliedPromo = null;
    notifyListeners();
  }

  // === DATA & MANAJEMEN STOK MENU ===
  List<Map<String, dynamic>> _allMenusWithStock = [];
  bool _isMenuLoading = false;

  List<Map<String, dynamic>> get allMenusWithStock => _allMenusWithStock;
  bool get isMenuLoading => _isMenuLoading;

  final List<Map<String, dynamic>> _localBaseMenus = [
    {"id": "a1", "name": "Aceh Gayo V60", "price": 32000, "image": "assets/images/acehgayov60.png", "category": "Kopi"},
    {"id": "a2", "name": "Amerikano", "price": 20000, "image": "assets/images/Americano.jpg", "category": "Kopi"},
    {"id": "a3", "name": "Caramel Latte", "price": 28000, "image": "assets/images/Caramellatte.jpg", "category": "Kopi"},
    {"id": "a4", "name": "Kopi Gula Aren", "price": 25000, "image": "assets/images/kopigulaaren.webp", "category": "Kopi"},
    {"id": "b1", "name": "Matcha Latte", "price": 28000, "image": "assets/images/matchalatte.webp", "category": "Non-Kopi"},
    {"id": "b2", "name": "Lemon Tea", "price": 18000, "image": "assets/images/lemontea.jpg", "category": "Non-Kopi"},
    {"id": "b3", "name": "Jus Strawberry", "price": 22000, "image": "assets/images/Jusstrawberry.jpg", "category": "Non-Kopi"},
    {"id": "b4", "name": "Almonds Chocolate", "price": 20000, "image": "assets/images/AlmondsChocolate.jpg", "category": "Non-Kopi"},
    {"id": "b5", "name": "Milk Shake", "price": 18000, "image": "assets/images/milkShake.jpg", "category": "Non-Kopi"},
    {"id": "c1", "name": "Mie Bangladesh", "price": 25000, "image": "assets/images/Miebangladesh.jpg", "category": "Food"},
    {"id": "c2", "name": "Nasi Goreng", "price": 30000, "image": "assets/images/nasigoreng.jpg", "category": "Food"},
    {"id": "c3", "name": "Ayam Pop", "price": 35000, "image": "assets/images/ayampop.webp", "category": "Food"},
    {"id": "c4", "name": "Ayam Sambal Geprek", "price": 20000, "image": "assets/images/ayamsambalgeprek.jpg", "category": "Food"},
    {"id": "c5", "name": "Nasi Beef Teriyaki", "price": 35000, "image": "assets/images/nasibeefteriyaki.jpg", "category": "Food"},
    {"id": "c6", "name": "Spaghetti Bologness", "price": 30000, "image": "assets/images/spaghettibologness.jpg", "category": "Food"},
    {"id": "d1", "name": "Roti Bakar", "price": 20000, "image": "assets/images/RotiBakar.jpg", "category": "Snack"},
    {"id": "d2", "name": "Donat", "price": 15000, "image": "assets/images/donat.jpg", "category": "Snack"},
    {"id": "d3", "name": "Cheesecake", "price": 27000, "image": "assets/images/cheesecake.jpg", "category": "Snack"},
    {"id": "d4", "name": "Cookies", "price": 15000, "image": "assets/images/cookies.jpg", "category": "Snack"},
    {"id": "d5", "name": "Burger", "price": 25000, "image": "assets/images/burger.jpg", "category": "Snack"},
  ];

  void listenToStockChanges() {
    _isMenuLoading = true;
    _supabase.from('menus').stream(primaryKey: ['id']).listen((dbMenus) {
      final Map<String, Map<String, dynamic>> combinedMap = {};

      for (var item in _localBaseMenus) {
        String idStr = item['id'].toString();
        combinedMap[idStr] = {
          'id': idStr,
          'name': item['name'],
          'price': item['price'],
          'category': item['category'],
          'image': item['image'],
          'stock': 20, 
          'isAsset': true,
        };
      }

      for (var item in dbMenus) {
        String idStr = item['id'].toString();
        combinedMap[idStr] = {
          'id': idStr,
          'name': item['name'] ?? '',
          'price': item['price'] ?? 0,
          'category': item['category'] ?? 'Kopi',
          'image': item['image_url'] ?? item['images_url'] ?? item['image'] ?? '',
          'stock': item['stock'] ?? 0,
          'isAsset': !(item['image_url'] != null && item['image_url'].toString().startsWith('http')),
        };
      }

      _allMenusWithStock = combinedMap.values.toList();
      _isMenuLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateStock(String id, int targetStock) async {
    try {
      final item = _allMenusWithStock.firstWhere((element) => element['id'] == id);
      
      // PERBAIKAN UTAMA: Mengubah 'images_url' menjadi 'image_url' sesuai struktur schema tabel database Anda
      await _supabase.from('menus').upsert({
        'id': id,
        'name': item['name'],
        'price': item['price'],
        'category': item['category'],
        'image_url': item['image'], 
        'stock': targetStock,
      });
    } catch (e) {
      debugPrint("Error sync stok ke Supabase: $e");
    }
  }

  Future<void> reduceStockAfterOrder(List<Map<String, dynamic>> cartItems) async {
    for (var cartItem in cartItems) {
      String itemId = cartItem['id'].toString();
      int qtyOrdered = cartItem['quantity'] ?? 1;

      try {
        final match = _allMenusWithStock.firstWhere((e) => e['id'] == itemId);
        int currentStock = match['stock'] ?? 0;
        int finalStock = (currentStock - qtyOrdered) < 0 ? 0 : (currentStock - qtyOrdered);
        await updateStock(itemId, finalStock);
      } catch (_) {}
    }
  }
}