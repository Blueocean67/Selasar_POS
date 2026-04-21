import 'package:flutter/material.dart';

class MenuGalleryPage extends StatelessWidget {
  const MenuGalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Data dummy gallery menggunakan asset asli kamu
    final List<Map<String, String>> galleryItems = [
      {"name": "Amerikano", "price": "Rp 20.000", "image": "assets/images/Amerikano.jpg"},
      {"name": "Caramel Latte", "price": "Rp 28.000", "image": "assets/images/Caramellatte.jpg"},
      {"name": "Matcha Latte", "price": "Rp 27.000", "image": "assets/images/matchalatte.webp"},
      {"name": "Kopi Gula Aren", "price": "Rp 25.000", "image": "assets/images/kopigulaaren.webp"},
      {"name": "Aceh Gayo v60", "price": "Rp 30.000", "image": "assets/images/acehgayov60.png"},
      {"name": "Mie Bangladesh", "price": "Rp 25.000", "image": "assets/images/Miebangladesh.jpg"},
      {"name": "Nasi Goreng", "price": "Rp 30.000", "image": "assets/images/nasigoreng.jpg"},
      {"name": "Ayam Pop", "price": "Rp 35.000", "image": "assets/images/ayampop.webp"},
      {"name": "Spaghetti Bolognese", "price": "Rp 32.000", "image": "assets/images/spagettibolognes.jpg"},
      {"name": "Burger Selasar", "price": "Rp 28.000", "image": "assets/images/burger.jpg"},
      {"name": "Roti Bakar", "price": "Rp 20.000", "image": "assets/images/RotiBakar.jpg"},
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF4A5D3F), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gallery Menu",
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, 
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 0.8, 
        ),
        itemCount: galleryItems.length,
        itemBuilder: (context, index) {
          return _buildGalleryItem(
            context,
            galleryItems[index]['name']!,
            galleryItems[index]['price']!,
            galleryItems[index]['image']!, 
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF4A5D3F),
        onPressed: () => Navigator.pushNamed(context, '/upload_menu'),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildGalleryItem(BuildContext context, String title, String price, String imagePath) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Stack(
                children: [
                  // MENGGUNAKAN Image.asset SESUAI REQUEST
                  Image.asset(
                    imagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    color: Color(0xFF4A5D3F),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}