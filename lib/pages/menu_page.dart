import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart'; 
import 'package:selasar_pos/provider/promo_provider.dart'; 
import 'package:selasar_pos/main.dart'; // Import pusat untuk mendeteksi order masuk

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const Color olive = Color(0xFF4A5D3F); 
  static const Color oliveLight = Color(0xFFB1B67C); 
  static const Color bg = Color(0xFFF8F9F2);    

  String selectedCategory = "Kopi";
  final List<String> categories = ["Kopi", "Non-Kopi", "Food", "Snack"];

  Map<String, int> cart = {};
  Map<String, Map<String, dynamic>> cartItemsData = {};
  Map<String, String> itemNotes = {}; 

  final Map<String, List<Map<String, dynamic>>> assetMenuData = {
    "Kopi": [
      {"id": "a1", "name": "Aceh Gayo V60", "price": 32000, "image": "assets/images/acehgayov60.png", "category": "Kopi", "desc": "Single Origin Aceh Gayo"},
      {"id": "a2", "name": "Amerikano", "price": 20000, "image": "assets/images/americano.jpg", "category": "Kopi", "isBestSeller": true},
      {"id": "a3", "name": "Signature Selasar Latte", "price": 28000, "image": "assets/images/Caramellatte.jpg", "category": "Kopi"},
      {"id": "a4", "name": "Kopi Gula Aren", "price": 25000, "image": "assets/images/kopigulaaren.webp", "category": "Kopi", "isBestSeller": true},
    ],
    "Non-Kopi": [
      {"id": "b1", "name": "Matcha Latte", "price": 28000, "image": "assets/images/matchalatte.webp", "category": "Non-Kopi", "desc": "Uji Matcha Grade A"},
      {"id": "b2", "name": "Lemon Tea", "price": 18000, "image": "assets/images/lemontea.jpg", "category": "Non-Kopi"},
      {"id": "b3", "name": "Jus Strawberry", "price": 22000, "image": "assets/images/Jusstrawberry.jpg", "category": "Non-Kopi"},
      {"id": "b4", "name": "Almonds Chocolate", "price": 20000, "image": "assets/images/AlmondsChocolate.jpg", "category": "Non-Kopi"},
      {"id": "b5", "name": "Milk Shake", "price": 18000, "image": "assets/images/milkshake.jpg", "category": "Non-Kopi"},
    ],
    "Food": [
      {"id": "c1", "name": "Mie Bangladesh", "price": 25000, "image": "assets/images/Miebangladesh.jpg", "category": "Food"},
      {"id": "c2", "name": "Nasi Goreng", "price": 30000, "image": "assets/images/nasigoreng.jpg", "category": "Food", "isBestSeller": true},
      {"id": "c3", "name": "Ayam Pop", "price": 35000, "image": "assets/images/ayampop.webp", "category": "Food"},
      {"id": "c4", "name": "Ayam Sambal Geprek", "price": 20000, "image": "assets/images/ayamsambalgeprek.jpg", "category": "Food"},
      {"id": "c5", "name": "Nasi Beef Teriyaki", "price": 35000, "image": "assets/images/nasibeefteriyaki.jpg", "category": "Food"},
      {"id": "c6", "name": "Spaghetti Bologness", "price": 30000, "image": "assets/images/spagettibolognes.jpg", "category": "Food"},
    ],
    "Snack": [
      {"id": "d1", "name": "Roti Bakar", "price": 20000, "image": "assets/images/RotiBakar.jpg", "category": "Snack"},
      {"id": "d2", "name": "Donat", "price": 15000, "image": "assets/images/donat.jpg", "category": "Snack"},
      {"id": "d3", "name": "Cheesecake", "price": 27000, "image": "assets/images/cheesecake.jpg", "category": "Snack"},
      {"id": "d4", "name": "Cookies", "price": 15000, "image": "assets/images/cookies.jpg", "category": "Snack"},
      {"id": "d5", "name": "Burger", "price": 25000, "image": "assets/images/burger.jpg", "category": "Snack"},
    ],
  };

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      if (mounted) {
        context.read<PromoProvider>().fetchPromosFromDatabase();
        _handleIncomingArguments();
      }
    });
  }

  void _handleIncomingArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('selected_product')) {
      final product = args['selected_product'] as Map<String, dynamic>;
      if (product.containsKey('id')) {
        _updateCart(product, 1);
        if (product.containsKey('category')) {
          setState(() {
            selectedCategory = product['category'].toString();
          });
        }
      }
    }
  }

  List<Map<String, dynamic>> _getCartItemsList() {
    return cart.keys.map((id) {
      final itemDetail = cartItemsData[id] ?? {};
      return {
        'id': id,
        'name': itemDetail['name'] ?? 'Menu',
        'price': itemDetail['price'] ?? 0,
        'quantity': cart[id] ?? 0,
        'qty': cart[id] ?? 0, 
        'category': itemDetail['category'] ?? '',
        'image': itemDetail['image'] ?? '',
        'note': itemNotes[id] ?? '',
      };
    }).toList();
  }

  void _updateCart(Map<String, dynamic> item, int delta, {String? note, int maxStock = 20}) {
    final id = item['id'].toString();
    setState(() {
      int current = cart[id] ?? 0;
      int newValue = current + delta;
      
      if (newValue > maxStock) {
        newValue = maxStock;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tidak bisa menambah item, batas stok tercapai.")),
        );
      }

      if (newValue <= 0) {
        cart.remove(id);
        cartItemsData.remove(id);
        itemNotes.remove(id);
      } else {
        cart[id] = newValue;
        cartItemsData[id] = item;
        if (note != null) {
          itemNotes[id] = note;
        }
      }
      
      final provider = context.read<PromoProvider>();
      int subtotal = _calculateSubtotal();
      if (provider.currentAppliedPromo != null) {
        provider.applyPromoByCode(provider.currentAppliedPromo!.code, subtotal, _getCartItemsList());
      }
    });
  }

  void _clearItemFromCart(String id) {
    setState(() {
      cart.remove(id);
      cartItemsData.remove(id);
      itemNotes.remove(id);
    });
  }

  int _calculateSubtotal() {
    int total = 0;
    cart.forEach((id, qty) {
      final priceData = cartItemsData[id]?['price'] ?? 0;
      int price = priceData is int ? priceData : double.parse(priceData.toString()).toInt();
      total += price * qty;
    });
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final promoProvider = context.watch<PromoProvider>();
    
    // ===== SINKRONISASI REALTIME ENGINE =====
    context.watch<OrderHistoryManager>(); 

    final user = Supabase.instance.client.auth.currentUser;
    final String? fotoUrl = user?.userMetadata?['avatar_url'];
    
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    String namaPemesan = "PELANGGAN";
    String nomorMeja = "--";
    String namaKasir = "STAFF";

    if (args is Map) {
      namaPemesan = args['customer_name']?.toString() ?? args['name']?.toString() ?? "PELANGGAN";
      nomorMeja = args['table_number']?.toString() ?? args['table']?.toString() ?? "--";
      namaKasir = args['cashier_name']?.toString() ?? "STAFF";
    }

    int subtotal = _calculateSubtotal();
    List<Map<String, dynamic>> currentCartItems = _getCartItemsList();
    
    int discount = promoProvider.calculateDiscount(subtotal, currentCartItems);
    String activePromoName = "";
    bool hasActivePromo = false;

    if (promoProvider.currentAppliedPromo != null) {
      final applied = promoProvider.currentAppliedPromo!;
      activePromoName = "${applied.code} - ${applied.description}";
      hasActivePromo = true;
    } else if (promoProvider.activePromos.isNotEmpty) {
      final firstPromo = promoProvider.activePromos.first;
      activePromoName = "Voucher Tersedia: ${firstPromo.code} (${firstPromo.description})";
      hasActivePromo = true;
    }

    int finalTotal = subtotal - discount;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                          ? NetworkImage(fotoUrl)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Selasar Ruang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        Text("KASIR : ${namaKasir.toUpperCase()}", style: const TextStyle(color: olive, fontSize: 10, fontWeight: FontWeight.bold)),
                        Text("PEMESAN : ${namaPemesan.toUpperCase()}", 
                          style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Spacer(),
                    _buildTableTag(nomorMeja),
                  ],
                ),
              ),
            ),

            if (hasActivePromo)
              SliverToBoxAdapter(
                child: _buildPromoBanner(context, activePromoName),
              ),

            SliverToBoxAdapter(child: _buildCategoryList()),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client.from('menus').stream(primaryKey: ['id']).eq('category', selectedCategory),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> dbMenus = snapshot.data ?? [];
                List<Map<String, dynamic>> assets = assetMenuData[selectedCategory] ?? [];
                
                final Map<String, Map<String, dynamic>> combinedMap = {};
                
                for (var item in assets) { 
                  combinedMap[item['id'].toString()] = item; 
                }
                
                for (var item in dbMenus) { 
                  combinedMap[item['id'].toString()] = {
                    'id': item['id'],
                    'name': item['name'],
                    'price': item['price'],
                    'category': item['category'],
                    'image': item['images_url'] ?? item['image_url'] ?? item['image'] ?? '',
                    'desc': item['description'] ?? item['desc'] ?? '',
                    'isBestSeller': item['is_bestseller'] ?? item['isBestSeller'] ?? false,
                    'isFromDb': true,
                    'stock': (item['stock'] == null || item['stock'] == 9999) ? 20 : item['stock'],
                  };
                }
                
                List<Map<String, dynamic>> displayMenus = combinedMap.values.toList();

                if (displayMenus.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("Belum ada menu di kategori ini", style: TextStyle(color: Colors.grey))),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final localItem = displayMenus[index];
                        final itemId = localItem['id'].toString();
                        
                        final providerItem = promoProvider.allMenusWithStock.firstWhere(
                          (e) => e['id'].toString() == itemId,
                          orElse: () => {},
                        );

                        int liveStock = providerItem['stock'] ?? localItem['stock'] ?? 20;
                        if (liveStock == 9999 || liveStock < 0) liveStock = 20; 

                        return _MenuCardFullWidth(
                          item: localItem,
                          qty: cart[itemId] ?? 0,
                          currentNote: itemNotes[itemId],
                          liveStock: liveStock,
                          onAdd: (note) => _updateCart(localItem, 1, note: note, maxStock: liveStock),
                          onRemove: () => _updateCart(localItem, -1),
                          onClearItem: () => _clearItemFromCart(itemId),
                        );
                      },
                      childCount: displayMenus.length,
                    ),
                  ),
                );
              },
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
      bottomNavigationBar: cart.isNotEmpty 
        ? _BottomCartPreview(
            subtotal: subtotal,
            discount: discount,
            totalPrice: finalTotal, 
            totalItems: cart.values.fold(0, (sum, q) => sum + q),
            cartData: cart,
            cartItemsDetails: cartItemsData,
            itemNotes: itemNotes,
            customerName: namaPemesan,
            tableNumber: nomorMeja,
            cashierName: namaKasir,
            currentCartList: currentCartItems,
          ) 
        : null,
    );
  }

  Widget _buildTableTag(String tableNum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(color: olive, borderRadius: BorderRadius.circular(20)),
      child: Text("Meja $tableNum", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildPromoBanner(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFD4A373).withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFD4A373)),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars, color: Color(0xFFD4A373)),
          const SizedBox(width: 10),
          Expanded(child: Text("Promo: $title", style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5E3C)), overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildCategoryList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text("Kategori", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: olive)),
        ),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            itemBuilder: (_, index) {
              final isSelected = selectedCategory == categories[index];
              return GestureDetector(
                onTap: () => setState(() => selectedCategory = categories[index]),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  margin: const EdgeInsets.only(right: 15),
                  decoration: BoxDecoration(
                    color: isSelected ? oliveLight : Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [if(!isSelected) BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        index == 0 ? Icons.coffee : index == 1 ? Icons.local_drink : index == 2 ? Icons.restaurant : Icons.fastfood,
                        color: isSelected ? Colors.white : olive,
                      ),
                      const SizedBox(height: 8),
                      Text(categories[index], style: TextStyle(color: isSelected ? Colors.white : olive, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MenuCardFullWidth extends StatefulWidget {
  final Map<String, dynamic> item;
  final int qty;
  final String? currentNote;
  final int liveStock;
  final Function(String?) onAdd;
  final VoidCallback onRemove;
  final VoidCallback onClearItem;

  const _MenuCardFullWidth({
    required this.item, 
    required this.qty, 
    this.currentNote, 
    required this.liveStock,
    required this.onAdd, 
    required this.onRemove,
    required this.onClearItem,
  });

  @override
  State<_MenuCardFullWidth> createState() => _MenuCardFullWidthState();
}

class _MenuCardFullWidthState extends State<_MenuCardFullWidth> {
  late bool _localAvailable;

  @override
  void initState() {
    super.initState();
    _localAvailable = widget.liveStock > 0;
  }

  @override
  void didUpdateWidget(_MenuCardFullWidth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.liveStock != widget.liveStock) {
      _localAvailable = widget.liveStock > 0;
    }
  }

  void _showVariantDialog(BuildContext context) {
    String category = widget.item['category'] ?? '';
    List<String> options = [];
    String title = "";

    if (category == "Kopi" || category == "Non-Kopi") {
      title = "Pilih Gula";
      options = ["Normal Sugar", "Less Sugar", "No Sugar"];
    } else if (category == "Food") {
      title = "Pilih Pedas";
      options = ["Biasa", "Sedang", "Pedas"];
    }

    if (options.isEmpty) { widget.onAdd(null); return; }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            ...options.map((opt) => ListTile(
              title: Text(opt),
              onTap: () { widget.onAdd(opt); Navigator.pop(context); },
            )),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const olive = Color(0xFF4A5D3F);
    bool isNetworkImage = widget.item['isFromDb'] == true && (widget.item['image'].toString().startsWith('http') || widget.item['image'].toString().startsWith('https'));
    bool finalAvailability = _localAvailable && (widget.liveStock > 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
            child: isNetworkImage 
              ? Image.network(widget.item['image'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => _errorImg())
              : Image.asset(widget.item['image'], height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => _errorImg()),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17), overflow: TextOverflow.ellipsis)),
                    Text("Rp ${widget.item['price']}", style: const TextStyle(fontWeight: FontWeight.bold, color: olive, fontSize: 16)),
                  ],
                ),
                if (widget.item['desc'] != null && widget.item['desc'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(widget.item['desc'], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                ],
                if (widget.currentNote != null) ...[
                  const SizedBox(height: 6),
                  Text("Notes: ${widget.currentNote}", style: const TextStyle(color: Color(0xFFD4A373), fontSize: 12, fontWeight: FontWeight.bold)),
                ],
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (widget.liveStock > 0) {
                          setState(() => _localAvailable = true);
                        }
                      },
                      child: _buildMiniStockBadge(
                        label: "Tersedia",
                        isActive: finalAvailability,
                        activeColor: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _localAvailable = false;
                        });
                        if (widget.qty > 0) {
                          widget.onClearItem();
                        }
                      },
                      child: _buildMiniStockBadge(
                        label: "Habis",
                        isActive: !finalAvailability,
                        activeColor: Colors.red,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                (!finalAvailability || widget.qty == 0)
                    ? SizedBox(width: double.infinity, child: _addButton(context, finalAvailability))
                    : _qtyController(finalAvailability),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniStockBadge({required String label, required bool isActive, required Color activeColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.12) : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? activeColor : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isActive ? activeColor : Colors.grey[400],
        ),
      ),
    );
  }

  Widget _errorImg() => Container(height: 180, color: Colors.grey[100], width: double.infinity, child: const Icon(Icons.image, color: Colors.grey));
  
  Widget _addButton(BuildContext context, bool isAvail) => ElevatedButton(
    onPressed: isAvail ? () => _showVariantDialog(context) : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: isAvail ? const Color(0xFFF8F9F2) : Colors.grey[300], 
      foregroundColor: isAvail ? const Color(0xFF4A5D3F) : Colors.grey[500],
      disabledBackgroundColor: Colors.grey[300],
      disabledForegroundColor: Colors.grey[400],
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      padding: const EdgeInsets.symmetric(vertical: 14),
    ),
    child: Text(isAvail ? "+ Tambah" : "Stok Habis", style: const TextStyle(fontWeight: FontWeight.bold)),
  );

  Widget _qtyController(bool isAvail) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      IconButton(onPressed: widget.onRemove, icon: const Icon(Icons.remove_circle_outline, color: Color(0xFF4A5D3F), size: 28)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 25),
        child: Text("${widget.qty}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      IconButton(
        onPressed: (isAvail && widget.qty < widget.liveStock) ? () => widget.onAdd(null) : null, 
        icon: Icon(
          Icons.add_circle, 
          color: (isAvail && widget.qty < widget.liveStock) ? const Color(0xFF4A5D3F) : Colors.grey[300], 
          size: 28
        ),
      ),
    ],
  );
}

class _BottomCartPreview extends StatefulWidget {
  final int subtotal;
  final int discount;
  final int totalPrice;
  final int totalItems;
  
  final Map<String, int> cartData;
  final Map<String, Map<String, dynamic>> cartItemsDetails;
  final Map<String, String> itemNotes;
  final String customerName;
  final String tableNumber;
  final String cashierName;
  final List<Map<String, dynamic>> currentCartList; 

  const _BottomCartPreview({
    required this.subtotal, 
    required this.discount, 
    required this.totalPrice, 
    required this.totalItems,
    required this.cartData,
    required this.cartItemsDetails,
    required this.itemNotes,
    required this.customerName,
    required this.tableNumber,
    required this.cashierName,
    required this.currentCartList,
  });

  @override
  State<_BottomCartPreview> createState() => _BottomCartPreviewState();
}

class _BottomCartPreviewState extends State<_BottomCartPreview> {
  final TextEditingController promoController = TextEditingController();

  @override
  void dispose() {
    promoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PromoProvider>(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(25, 15, 25, 35),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    controller: promoController,
                    decoration: InputDecoration(
                      hintText: provider.currentAppliedPromo != null 
                          ? "Voucher aktif: ${provider.currentAppliedPromo!.code}" 
                          : "Masukkan kode voucher",
                      hintStyle: const TextStyle(fontSize: 12),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  String? errorMsg = provider.applyPromoByCode(
                    promoController.text.trim(), 
                    widget.subtotal, 
                    widget.currentCartList
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMsg ?? "Promo berhasil diterapkan!"),
                      backgroundColor: errorMsg == null ? Colors.green : Colors.red,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4A5D3F),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text("Pakai", style: TextStyle(color: Colors.white, fontSize: 12)),
              )
            ],
          ),
          const SizedBox(height: 12),
          _row("Subtotal", "Rp ${widget.subtotal}", Colors.grey),
          if (widget.discount > 0) _row("Diskon Promo", "- Rp ${widget.discount}", Colors.red),
          const Divider(),
          _row("Total", "Rp ${widget.totalPrice}", const Color(0xFF4A5D3F), isBold: true),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/order_summary',
                arguments: {
                  'customer_name': widget.customerName,
                  'table_number': widget.tableNumber,
                  'cashier_name': widget.cashierName,
                  'subtotal': widget.subtotal.toDouble(),
                  'discount': widget.discount.toDouble(),
                  'total_price': widget.totalPrice.toDouble(),
                  'items': widget.currentCartList, 
                },
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A5D3F),
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            ),
            child: Text("LANJUT KE PEMBAYARAN (${widget.totalItems})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String val, Color col, {bool isBold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: col, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(val, style: TextStyle(fontSize: isBold ? 18 : 14, fontWeight: FontWeight.bold, color: col)),
      ],
    ),
  );
}