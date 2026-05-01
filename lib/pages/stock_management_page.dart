import 'package:flutter/material.dart';

class StockManagementPage extends StatefulWidget {
  const StockManagementPage({super.key});

  @override
  State<StockManagementPage> createState() => _StockManagementPageState();
}

class _StockManagementPageState extends State<StockManagementPage> {
  // Brand Colors Selasar
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);
  static const Color accentGold = Color(0xFFBC8E5B);

  String searchQuery = "";
  String selectedCategory = "Semua";
  final List<String> categories = ["Semua", "Coffee", "Non-Coffee", "Food", "Snack"];

  // Simulasi Data Database (Fadilah bisa konekkan ke Supabase nanti)
  final List<Map<String, dynamic>> masterMenu = [
    {"id": "1", "name": "Amerikano", "cat": "Coffee", "stock": true, "img": "assets/images/Amerikano.jpg"},
    {"id": "2", "name": "Caramel Latte", "cat": "Coffee", "stock": false, "img": "assets/images/Caramellatte.jpg"},
    {"id": "3", "name": "Matcha Latte", "cat": "Non-Coffee", "stock": true, "img": "assets/images/matchalatte.webp"},
    {"id": "4", "name": "Mie Bangladesh", "cat": "Food", "stock": true, "img": "assets/images/Miebangladesh.jpg"},
    {"id": "5", "name": "Nasi Goreng", "cat": "Food", "stock": false, "img": "assets/images/nasigoreng.jpg"},
    {"id": "6", "name": "Cheesecake", "cat": "Snack", "stock": true, "img": "assets/images/cheesecake.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    // Logic Filter & Search Otomatis
    final filteredMenu = masterMenu.where((item) {
      final matchesSearch = item['name'].toLowerCase().contains(searchQuery.toLowerCase());
      final matchesCat = selectedCategory == "Semua" || item['cat'] == selectedCategory;
      return matchesSearch && matchesCat;
    }).toList();

    return Scaffold(
      backgroundColor: bgSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: _buildSearchField(),
            ),
          ),
          SliverToBoxAdapter(child: _buildCategoryChips()),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildStockCard(filteredMenu[index]),
                childCount: filteredMenu.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      backgroundColor: Colors.white,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Text("KONTROL STOK", 
        style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2)),
      centerTitle: true,
    );
  }

  Widget _buildSearchField() {
    return TextField(
      onChanged: (value) => setState(() => searchQuery = value),
      decoration: InputDecoration(
        hintText: "Cari menu Selasar...",
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
              onSelected: (val) => setState(() => selectedCategory = categories[index]),
              selectedColor: primaryGreen,
              backgroundColor: Colors.white,
              labelStyle: TextStyle(color: isSelected ? Colors.white : primaryGreen, fontWeight: FontWeight.bold, fontSize: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildStockCard(Map<String, dynamic> item) {
    bool isAvailable = item['stock'];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          // Image with Grayscale Filter
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ColorFiltered(
              colorFilter: isAvailable 
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : const ColorFilter.mode(Colors.grey, BlendMode.saturation),
              child: Image.asset(item['img'], width: 65, height: 65, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(width: 65, height: 65, color: Colors.grey[100])),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(isAvailable ? "TERSEDIA" : "HABIS", 
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: isAvailable ? Colors.green : Colors.red, letterSpacing: 1)),
              ],
            ),
          ),
          // Toggle Switch Pro
          Switch(
            value: isAvailable,
            activeThumbColor: primaryGreen,
            onChanged: (val) {
              setState(() {
                item['stock'] = val;
              });
              // LOGIC: Disini Fadilah bisa tambahin fungsi Update ke Supabase
            },
          ),
        ],
      ),
    );
  }
}