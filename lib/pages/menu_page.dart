import 'package:flutter/material.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> {
  String selectedCategory = "Coffee";
  final List<String> categories = ["Coffee", "Non-Coffee", "Food", "Snack"];

  final Map<String, List<Map<String, String>>> menuData = {
    "Coffee": [
      {"name": "Amerikano", "price": "20.000", "image": "assets/images/Amerikano.jpg", "desc": "Strong & Bold black coffee"},
      {"name": "Caramel Latte", "price": "28.000", "image": "assets/images/Caramellatte.jpg", "desc": "Sweet & Creamy caramel"},
      {"name": "Kopi Gula Aren", "price": "25.000", "image": "assets/images/kopigulaaren.webp", "desc": "Authentic Indonesian taste"},
      {"name": "Aceh Gayo v60", "price": "30.000", "image": "assets/images/acehgayov60.png", "desc": "Biji Kopi Arabika Aceh Gayo Natural Manual Brew V60"},
    ],
    "Non-Coffee": [
      {"name": "Matcha Latte", "price": "27.000", "image": "assets/images/matchalatte.webp", "desc": "Pure Japanese green tea"},
      {"name": "Jus Strawberry", "price": "22.000", "image": "assets/images/Jusstrawberry.jpg", "desc": "Fresh from the field"},
      {"name": "Lemon Tea", "price": "18.000", "image": "assets/images/lemontea.jpg", "desc": "Refreshing citrus tea"},
    ],
    "Food": [
      {"name": "Mie Bangladesh", "price": "25.000", "image": "assets/images/Miebangladesh.jpg", "desc": "Spicy & Rich in spices"},
      {"name": "Nasi Goreng", "price": "30.000", "image": "assets/images/nasigoreng.jpg", "desc": "Special Selasar recipe"},
      {"name": "Ayam Pop", "price": "35.000", "image": "assets/images/ayampop.webp", "desc": "Tender & Savory chicken"},
    ],
    "Snack": [
      {"name": "Cheesecake", "price": "25.000", "image": "assets/images/cheesecake.jpg", "desc": "Soft & Melts in your mouth"},
      {"name": "Roti Bakar", "price": "20.000", "image": "assets/images/RotiBakar.jpg", "desc": "Crunchy with chocolate topping"},
      {"name": "Cookies", "price": "15.000", "image": "assets/images/cookies.jpg", "desc": "Perfect coffee companion"},
    ],
  };

  @override
  Widget build(BuildContext context) {
    var currentMenu = menuData[selectedCategory] ?? [];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5D3F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pilih Menu",
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView( // PERBAIKAN: Gunakan SingleChildScrollView di body
        child: Column(
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
                    padding: const EdgeInsets.only(right: 8, top: 12, bottom: 12),
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() => selectedCategory = categories[index]);
                      },
                      selectedColor: const Color(0xFF4A5D3F),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : const Color(0xFF4A5D3F),
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  );
                },
              ),
            ),
            // PERBAIKAN: Hapus 'Expanded' dan tambahkan 'shrinkWrap' + 'physics'
            GridView.builder(
              padding: const EdgeInsets.all(20),
              shrinkWrap: true, // WAJIB ada agar tidak error RenderBox
              physics: const NeverScrollableScrollPhysics(), // Biar scroll ditangani SingleChildScrollView
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
              ),
              itemCount: currentMenu.length,
              itemBuilder: (context, index) {
                return _buildMenuCard(currentMenu[index]);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomCart(),
    );
  }

  Widget _buildMenuCard(Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.asset(
                item['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Icon(Icons.fastfood, color: Colors.grey),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']!, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item['desc']!, 
                  style: const TextStyle(color: Colors.grey, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Rp ${item['price']}", 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F), fontSize: 13)
                    ),
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Color(0xFF4A5D3F), shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 14),
                      ),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBottomCart() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.pushNamed(context, '/summary');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF4A5D3F),
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 60),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("2 Items", style: TextStyle(fontSize: 13, color: Colors.white70)),
            Text("Checkout Pesanan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text("Rp 53rb", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}