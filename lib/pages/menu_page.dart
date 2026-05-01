import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);

  String selectedCategory = "Coffee";
  final List<String> categories = ["Coffee", "Non-Coffee", "Food", "Snack"];

  Map<String, int> cart = {};
  Map<String, Map<String, dynamic>> cartItemsData = {};

  // Data tambahan/lokal yang kamu berikan
  final Map<String, List<Map<String, dynamic>>> menuData = {
    "Coffee": [
      {"id": "c1", "name": "Amerikano", "price": 20000, "image": "assets/images/Amerikano.jpg", "desc": "Strong & Bold black coffee", "isAvailable": true},
      {"id": "c2", "name": "Caramel Latte", "price": 28000, "image": "assets/images/Caramellatte.jpg", "desc": "Sweet & Creamy caramel", "isAvailable": false},
      {"id": "c3", "name": "Kopi Gula Aren", "price": 25000, "image": "assets/images/kopigulaaren.webp", "desc": "Authentic Indonesian taste", "isAvailable": true},
      {"id": "c4", "name": "Aceh Gayo v60", "price": 30000, "image": "assets/images/acehgayov60.png", "desc": "Biji Kopi Arabika Aceh Gayo", "isAvailable": true},
    ],
    "Non-Coffee": [
      {"id": "nc1", "name": "Matcha Latte", "price": 27000, "image": "assets/images/matchalatte.webp", "desc": "Pure Japanese green tea", "isAvailable": true},
      {"id": "nc2", "name": "Jus Strawberry", "price": 22000, "image": "assets/images/Jusstrawberry.jpg", "desc": "Fresh from the field", "isAvailable": true},
    ],
    "Food": [
      {"id": "f1", "name": "Mie Bangladesh", "price": 25000, "image": "assets/images/Miebangladesh.jpg", "desc": "Spicy & Rich in spices", "isAvailable": true},
      {"id": "f2", "name": "Nasi Goreng", "price": 30000, "image": "assets/images/nasigoreng.jpg", "desc": "Special Selasar recipe", "isAvailable": false},
    ],
    "Snack": [
      {"id": "s1", "name": "Cheesecake", "price": 25000, "image": "assets/images/cheesecake.jpg", "desc": "Soft & Melts in your mouth", "isAvailable": true},
    ],
  };

  Stream<List<Map<String, dynamic>>> _getMenuStream() {
    return Supabase.instance.client
        .from('menus')
        .stream(primaryKey: ['id'])
        .eq('category', selectedCategory);
  }

  void _updateCart(Map<String, dynamic> item, int delta) {
    final String id = item['id'].toString();
    setState(() {
      int current = cart[id] ?? 0;
      int newValue = current + delta;
      
      if (newValue <= 0) {
        cart.remove(id);
        cartItemsData.remove(id);
      } else {
        cart[id] = newValue;
        cartItemsData[id] = item;
      }
    });
  }

  void _removeItem(String id) {
    setState(() {
      cart.remove(id);
      cartItemsData.remove(id);
    });
  }

  double _calculateTotal() {
    double total = 0;
    cart.forEach((id, qty) {
      final price = cartItemsData[id]?['price'] ?? 0;
      total += (price is int ? price.toDouble() : double.parse(price.toString())) * qty;
    });
    return total;
  }

  int _totalItems() => cart.values.fold(0, (sum, item) => sum + item);

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
        title: const Text("Menu Selasar", 
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryGreen, letterSpacing: 1)),
      ),
      body: Column(
        children: [
          Container(
            height: 70,
            color: Colors.white,
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
                      if (val) setState(() => selectedCategory = categories[index]);
                    },
                    selectedColor: primaryGreen,
                    backgroundColor: bgSurface,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : primaryGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 12
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    showCheckmark: false,
                  ),
                );
              },
            ),
          ),
          
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMenuStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: primaryGreen));
                }
                
                // Gunakan data dari Supabase jika ada, jika tidak gunakan menuData lokal berdasarkan kategori
                final menus = (snapshot.hasData && snapshot.data!.isNotEmpty) 
                    ? snapshot.data! 
                    : menuData[selectedCategory] ?? [];

                if (menus.isEmpty) {
                  return const Center(child: Text("Menu belum tersedia, Fad."));
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 20,
                    crossAxisSpacing: 20,
                    childAspectRatio: 0.65,
                  ),
                  itemCount: menus.length,
                  itemBuilder: (context, index) {
                    final item = menus[index];
                    final String id = item['id'].toString();
                    int qty = cart[id] ?? 0;
                    
                    return _MenuCard(
                      item: item,
                      qty: qty,
                      onAdd: () => _updateCart(item, 1),
                      onRemove: () => _updateCart(item, -1),
                      onDelete: () => _removeItem(id),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _totalItems() > 0 
          ? _BottomCartPreview(totalPrice: _calculateTotal(), totalItems: _totalItems()) 
          : null,
    );
  }
}

class _MenuCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final int qty;
  final VoidCallback onAdd;
  final VoidCallback onRemove;
  final VoidCallback onDelete;

  const _MenuCard({required this.item, required this.qty, required this.onAdd, required this.onRemove, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    // Menyesuaikan dengan key 'isAvailable' dari data barumu
    final bool isAvailable = item['isAvailable'] ?? (item['stock'] != null ? item['stock'] > 0 : true);
    
    // Menyesuaikan dengan key 'image' atau 'image_url'
    String rawImg = item['image'] ?? item['images_url'] ?? item['image_url'] ?? '';
    Widget imageWidget;

    if (rawImg.startsWith('http')) {
      imageWidget = Image.network(
        rawImg,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.broken_image)),
      );
    } else {
      String assetPath = rawImg.contains('assets/') ? rawImg : 'assets/images/$rawImg';
      imageWidget = Image.asset(
        assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.coffee)),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Opacity(
                    opacity: isAvailable ? 1.0 : 0.5,
                    child: imageWidget,
                  ),
                ),
                if (!isAvailable)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                    ),
                    child: const Center(
                      child: Text("HABIS", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 2, shadows: [Shadow(blurRadius: 5, color: Colors.black)])),
                    ),
                  ),
                if (qty > 0)
                  Positioned(
                    right: 8, top: 8,
                    child: CircleAvatar(
                      backgroundColor: const Color(0xFF4A5D3F),
                      radius: 12,
                      child: Text(qty.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  )
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'] ?? 'Menu', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF2D3329)), maxLines: 1),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(item['price'] is String ? double.parse(item['price']) : item['price'] ?? 0)}", 
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF4A5D3F), fontSize: 12)),
                    if (isAvailable) 
                      qty == 0 ? _buildAddButton() : _buildQtyCounter()
                    else
                      const Icon(Icons.block, size: 18, color: Colors.grey),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: const BoxDecoration(color: Color(0xFF4A5D3F), shape: BoxShape.circle),
        child: const Icon(Icons.add, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildQtyCounter() {
    return Row(
      children: [
        GestureDetector(onTap: onRemove, child: const Icon(Icons.remove_circle_outline, color: Color(0xFF4A5D3F), size: 20)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onDelete, child: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18)),
        const SizedBox(width: 4),
        GestureDetector(onTap: onAdd, child: const Icon(Icons.add_circle, color: Color(0xFF4A5D3F), size: 20)),
      ],
    );
  }
}

class _BottomCartPreview extends StatelessWidget {
  final double totalPrice;
  final int totalItems;
  const _BottomCartPreview({required this.totalPrice, required this.totalItems});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, -5))],
      ),
      child: ElevatedButton(
        onPressed: () => Navigator.pushNamed(context, '/summary'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A5D3F),
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("$totalItems Produk", style: const TextStyle(fontSize: 10, color: Colors.white70)),
                Text("Rp ${NumberFormat.currency(locale: 'id', symbol: '', decimalDigits: 0).format(totalPrice)}", 
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Colors.white)),
              ],
            ),
            const Row(
              children: [
                Text("LANJUT CHECKOUT", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Colors.white, letterSpacing: 1)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white),
              ],
            ),
          ],
        ),
      ),
    );
  }
}