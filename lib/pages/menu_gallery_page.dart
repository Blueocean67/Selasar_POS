import 'package:flutter/material.dart';
import 'dart:ui';

// Model Data dengan ID untuk memudahkan delete
class MenuItem {
  final String id;
  final String name;
  final String price;
  final String image;
  final String category;

  MenuItem({required this.id, required this.name, required this.price, required this.image, required this.category});
}

class MenuGalleryPage extends StatefulWidget {
  const MenuGalleryPage({super.key});

  @override
  State<MenuGalleryPage> createState() => _MenuGalleryPageState();
}

class _MenuGalleryPageState extends State<MenuGalleryPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color scaffoldBg = Color(0xFFF8F9F2);

  // Controller untuk fitur Search Otomatis
  final TextEditingController _searchController = TextEditingController();
  
  // Data Master
  final List<MenuItem> _allMenu = [
    MenuItem(id: "1", name: "Amerikano", price: "Rp 20.000", image: "assets/images/Amerikano.jpg", category: "Coffee"),
    MenuItem(id: "2", name: "Caramel Latte", price: "Rp 28.000", image: "assets/images/Caramellatte.jpg", category: "Coffee"),
    MenuItem(id: "3", name: "Matcha Latte", price: "Rp 27.000", image: "assets/images/matchalatte.webp", category: "Non-Coffee"),
    MenuItem(id: "4", name: "Kopi Gula Aren", price: "Rp 25.000", image: "assets/images/kopigulaaren.webp", category: "Coffee"),
    MenuItem(id: "5", name: "Mie Bangladesh", price: "Rp 25.000", image: "assets/images/Miebangladesh.jpg", category: "Food"),
    MenuItem(id: "6", name: "Nasi Goreng", price: "Rp 30.000", image: "assets/images/nasigoreng.jpg", category: "Food"),
  ];

  // Data yang ditampilkan (Hasil Filter)
  List<MenuItem> _filteredMenu = [];

  @override
  void initState() {
    super.initState();
    _filteredMenu = _allMenu; // Awalnya tampilkan semua
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // LOGIC SEARCH OTOMATIS
  void _onSearchChanged() {
    setState(() {
      _filteredMenu = _allMenu
          .where((item) => item.name.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  // LOGIC DELETE DENGAN ANIMASI SNACKBAR
  void _deleteItem(String id) {
    setState(() {
      _allMenu.removeWhere((item) => item.id == id);
      _onSearchChanged(); // Update hasil filter setelah delete
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Menu berhasil dihapus dari katalog"),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.redAccent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(context),
            _buildSearchBar(),
            _filteredMenu.isEmpty ? _buildEmptyState() : _buildGridContent(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: primaryGreen,
        onPressed: () => Navigator.pushNamed(context, '/upload_menu'),
        icon: const Icon(Icons.add_a_photo_rounded, color: Colors.white),
        label: const Text("ADD MENU", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      backgroundColor: scaffoldBg,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: const Column(
        children: [
          Text("KATALOG SELASAR", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 2)),
          Text("Premium Gallery", style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverToBoxAdapter(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.5)),
              ),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: "Cari rasa yang tertinggal...",
                  hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: primaryGreen),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return SliverFillRemaining(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text("Menu tidak ditemukan", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildGridContent() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 20,
          crossAxisSpacing: 20,
          childAspectRatio: 0.7,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            // Animasi masuk satu-satu (Fade In)
            return TweenAnimationBuilder(
              duration: Duration(milliseconds: 300 + (index * 100)),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Opacity(opacity: value, child: Transform.translate(offset: Offset(0, 20 * (1 - value)), child: child));
              },
              child: _MenuCard(
                item: _filteredMenu[index],
                onDelete: () => _showDeleteConfirm(_filteredMenu[index]),
              ),
            );
          },
          childCount: _filteredMenu.length,
        ),
      ),
    );
  }

  // MODAL KONFIRMASI DELETE AESTHETIC
  void _showDeleteConfirm(MenuItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Hapus Menu?", style: TextStyle(fontWeight: FontWeight.w900)),
        content: Text("Menu '${item.name}' bakal ilang selamanya dari galeri lo."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("BATAL", style: TextStyle(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              _deleteItem(item.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text("HAPUS", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final MenuItem item;
  final VoidCallback onDelete;
  const _MenuCard({required this.item, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
                  child: Image.asset(
                    item.image,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.grey[100], child: const Icon(Icons.coffee)),
                  ),
                ),
                // Tombol Delete di Pojok Atas
                Positioned(
                  top: 10, right: 10,
                  child: GestureDetector(
                    onTap: onDelete,
                    child: ClipRRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.2), shape: BoxShape.circle),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.category.toUpperCase(), style: const TextStyle(color: Color(0xFFBC8E5B), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF2D3329)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.price, style: const TextStyle(color: Color(0xFF4A5D3F), fontWeight: FontWeight.w900, fontSize: 13)),
                    const Icon(Icons.star_rounded, size: 14, color: Color(0xFFBC8E5B)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}