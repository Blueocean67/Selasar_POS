import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// --- CONFIGURATION TEMA WARNA (HIJAU AGAK MUDA & SEGAR) ---
class GalleryTheme {
  static const Color primary = Color(0xFFC2C794); 
  static const Color priceColor = Color(0xFF5A734E); 
  static const Color background = Color(0xFFFDFDF9);
  static const Color textSecondary = Color(0xFF8B8F80);
  static const Color customGreen = Color(0xFFB1B67C); 
}

class MenuGalleryPage extends StatefulWidget {
  const MenuGalleryPage({super.key});

  @override
  State<MenuGalleryPage> createState() => _MenuGalleryPageState();
}

class _MenuGalleryPageState extends State<MenuGalleryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = "Semua";
  final List<String> _categories = ["Semua", "Kopi", "Non-Kopi", "Snack", "Food"];
  
  final StreamController<List<Map<String, dynamic>>> _combinedStreamController = StreamController<List<Map<String, dynamic>>>.broadcast();
  StreamSubscription<List<Map<String, dynamic>>>? _supabaseSubscription;

  // Data Lokal Asset Dasar
  final Map<String, List<Map<String, dynamic>>> assetMenuData = {
    "Kopi": [
      {"id": "a1", "name": "Aceh Gayo V60", "price": 32000, "image": "assets/images/acehgayov60.png", "category": "Kopi", "desc": "Single Origin Aceh Gayo"},
      {"id": "a2", "name": "Amerikano", "price": 20000, "image": "assets/images/americano.jpg", "category": "Kopi"},
      {"id": "a3", "name": "Signature Selasar Latte", "price": 28000, "image": "assets/images/Caramellatte.jpg", "category": "Kopi"},
      {"id": "a4", "name": "Kopi Gula Aren", "price": 25000, "image": "assets/images/kopigulaaren.webp", "category": "Kopi"},
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
      {"id": "c2", "name": "Nasi Goreng", "price": 30000, "image": "assets/images/nasigoreng.jpg", "category": "Food"},
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

  // --- KAMPUS NORMALISASI BAHASA: Mengamankan data masuk dari Supabase ---
  String _mapCategoryToLocal(String dbCategory) {
    String clean = dbCategory.trim().toLowerCase();
    if (clean == 'coffee' || clean == 'kopi') return 'Kopi';
    if (clean == 'non-coffee' || clean == 'non kopi' || clean == 'non-kopi') return 'Non-Kopi';
    if (clean == 'snack' || clean == 'makanan ringan') return 'Snack';
    if (clean == 'food' || clean == 'makanan berat' || clean == 'makanan') return 'Food';
    return 'Kopi'; 
  }

  // PERBAIKAN: Disamakan dengan data lokal agar penapisan data kategori minuman tidak pecah
  String _mapCategoryToDb(String localCategory) {
    if (localCategory == 'Kopi') return 'Kopi';
    if (localCategory == 'Non-Kopi') return 'Non-Kopi';
    return localCategory; 
  }

  @override
  void initState() {
    super.initState();
    _initRealtimeSupabaseStream();
  }

  void _initRealtimeSupabaseStream() {
    _supabaseSubscription?.cancel();
    try {
      _supabaseSubscription = Supabase.instance.client
          .from('menus')
          .stream(primaryKey: ['id'])
          .listen((List<Map<String, dynamic>> dbMenus) {
            if (!mounted) return;
            
            List<Map<String, dynamic>> combinedList = [];
            
            for (var categoryList in assetMenuData.values) {
              for (var assetItem in categoryList) {
                combinedList.add({
                  'id': assetItem['id'].toString(),
                  'name': assetItem['name'],
                  'price': assetItem['price'],
                  'category': assetItem['category'],
                  'image': assetItem['image'] ?? '',
                  'desc': assetItem['desc'] ?? '',
                  'stock': 20,
                  'is_available': true,
                  'isFromDb': false,
                });
              }
            }

            for (var dbItem in dbMenus) {
              String dbId = dbItem['id'].toString();
              String imgUrl = (dbItem['image_url'] ?? dbItem['image'] ?? dbItem['images_url'] ?? '').toString();
              String cleanCategory = _mapCategoryToLocal(dbItem['category'] ?? 'Kopi');
              
              int index = combinedList.indexWhere((element) => element['id'].toString() == dbId);
              
              Map<String, dynamic> normalizedItem = {
                'id': dbId,
                'name': dbItem['name'] ?? '',
                'price': int.tryParse(dbItem['price'].toString()) ?? 0,
                'category': cleanCategory,
                'image': imgUrl,
                'desc': dbItem['description'] ?? dbItem['desc'] ?? '',
                'stock': int.tryParse(dbItem['stock'].toString()) ?? 20,
                'is_available': dbItem['is_available'] ?? true,
                'isFromDb': true,
              };

              if (index != -1) {
                combinedList[index] = normalizedItem;
              } else {
                combinedList.insert(0, normalizedItem);
              }
            }

            _combinedStreamController.add(combinedList);
          }, onError: (error) {
            debugPrint("Koneksi Stream Gagal: $error");
          });
    } catch (e) {
      debugPrint("Gagal menginisialisasi Realtime Stream Supabase: $e");
      _emitFallback();
    }
  }

  void _emitFallback() {
    List<Map<String, dynamic>> fallbackList = [];
    for (var list in assetMenuData.values) {
      for (var item in list) {
        fallbackList.add({
          'id': item['id'].toString(),
          'name': item['name'],
          'price': item['price'],
          'category': item['category'],
          'image': item['image'] ?? '',
          'desc': item['desc'] ?? '',
          'stock': 20,
          'is_available': true,
          'isFromDb': false,
        });
      }
    }
    _combinedStreamController.add(fallbackList);
  }

  void _openEditBottomSheet(Map<String, dynamic> item) {
    final nameController = TextEditingController(text: item['name']);
    final priceController = TextEditingController(text: item['price'].toString());
    final descController = TextEditingController(text: item['desc']);
    final imageController = TextEditingController(text: item['image']);
    String currentCategory = _mapCategoryToLocal(item['category'] ?? 'Kopi');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 25,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Edit Detail Menu", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: GalleryTheme.priceColor)),
                const SizedBox(height: 15),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Nama Menu", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Harga (Rp)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  decoration: const InputDecoration(labelText: "Deskripsi", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: imageController,
                  decoration: const InputDecoration(labelText: "URL Foto / Path Asset", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 15),
                StatefulBuilder(
                  builder: (context, setBottomSheetState) => DropdownButtonFormField<String>(
                    value: currentCategory,
                    decoration: const InputDecoration(labelText: "Kategori", border: OutlineInputBorder()),
                    items: ["Kopi", "Non-Kopi", "Snack", "Food"].map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setBottomSheetState(() => currentCategory = val);
                    },
                  ),
                ),
                const SizedBox(height: 25),
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context); 
                    await _updateMenuInDatabase(
                      id: item['id'],
                      name: nameController.text.trim(),
                      price: int.tryParse(priceController.text) ?? 0,
                      desc: descController.text.trim(),
                      img: imageController.text.trim(),
                      cat: currentCategory,
                      isFromDb: item['isFromDb'] ?? false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalleryTheme.priceColor,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Simpan Perubahan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 25),
              ],
            ),
          ),
        );
      },
    );
  }

 Future<void> _updateMenuInDatabase({
  required String id,
  required String name,
  required int price,
  required String desc,
  required String img,
  required String cat,
  required bool isFromDb,
}) async {
  try {
    final supabase = Supabase.instance.client;
    final String dbMappedCategory = _mapCategoryToDb(cat);

    final payload = {
      'name': name,
      'price': price,
      'description': desc,
      'image_url': img,
      'category': dbMappedCategory,
      'stock': 20,
      'is_available': true,
    };

    if (isFromDb) {
      await supabase.from('menus').update(payload).eq('id', id);
    } else {
      await supabase.from('menus').insert(payload);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Berhasil diperbarui/ditambahkan!"), backgroundColor: Colors.green),
      );
      _refreshData(); 
    }
  } catch (e) {
    debugPrint("Gagal memperbarui: $e");
  }
}

  Future<void> _deleteMenu(String id) async {
    try {
      await Supabase.instance.client.from('menus').delete().eq('id', id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Menu berhasil dihapus dari sistem pusat"), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      debugPrint("Gagal menghapus menu dari database: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> _getAdaptiveStream() {
    return _combinedStreamController.stream;
  }

  void _refreshData() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.dispose();
    _supabaseSubscription?.cancel();
    _combinedStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String? fotoUrl;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      fotoUrl = user?.userMetadata?['avatar_url'];
    } catch (_) {}

    return Scaffold(
      backgroundColor: GalleryTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: (fotoUrl != null && fotoUrl.isNotEmpty)
                          ? NetworkImage(fotoUrl)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                    const SizedBox(width: 12),
                    const Text("Selasar Ruang", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: GalleryTheme.primary),
                      onPressed: () => _refreshData(),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("CATALOG MANAGEMENT", style: TextStyle(color: GalleryTheme.textSecondary, letterSpacing: 1.2, fontSize: 10, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Menu Gallery", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                    SizedBox(height: 25),
                  ],
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, '/upload_menu').then((value) {
                      _refreshData();
                    });
                  },
                  icon: const Icon(Icons.add, color: Colors.white),
                  label: const Text("Tambah Menu Baru", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GalleryTheme.customGreen, 
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (v) => setState(() {}),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: "Cari menu...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      height: 40,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          bool isSelected = _selectedCategory == _categories[index];
                          
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: ChoiceChip(
                              label: Text(_categories[index]),
                              selected: isSelected,
                              onSelected: (val) {
                                setState(() => _selectedCategory = _categories[index]);
                              },
                              selectedColor: GalleryTheme.customGreen, 
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                              )
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getAdaptiveStream(),
              builder: (context, snapshot) {
                List<Map<String, dynamic>> currentMenus = snapshot.data ?? [];

                final filteredList = currentMenus.where((item) {
                  final nameMatch = item['name'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
                  final categoryMatch = _selectedCategory == "Semua" || item['category'].toString().toLowerCase() == _selectedCategory.toLowerCase();
                  return nameMatch && categoryMatch;
                }).toList();

                if (filteredList.isEmpty && snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator(color: GalleryTheme.priceColor)),
                  );
                }

                if (filteredList.isEmpty) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: Text("Menu tidak ditemukan dalam katalog", style: TextStyle(color: Colors.grey))),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildCard(filteredList[index]),
                      childCount: filteredList.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    String imgPath = item['image'] ?? '';
    bool isNetwork = imgPath.startsWith('http') || imgPath.contains('supabase') || imgPath.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                child: isNetwork 
                  ? (imgPath.isNotEmpty 
                      ? Image.network(imgPath, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => _errorImg())
                      : _errorImg())
                  : Image.asset(imgPath, height: 180, width: double.infinity, fit: BoxFit.cover, errorBuilder: (c,e,s) => _errorImg()),
              ),
              Positioned(
                top: 10, right: 10,
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9), radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.orange, size: 16),
                        onPressed: () => _openEditBottomSheet(item), 
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.9), radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                        onPressed: () => _showDeleteDialog(item['id'].toString(), item['name']),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ListTile(
            title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(item['category'] ?? '', style: const TextStyle(color: GalleryTheme.textSecondary, fontSize: 13)),
            trailing: Text(
              "Rp ${item['price']}", 
              style: const TextStyle(
                color: GalleryTheme.priceColor, 
                fontWeight: FontWeight.bold, 
                fontSize: 16
              )
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorImg() => Container(
    height: 180, 
    width: double.infinity,
    color: const Color(0xFFF0F1EA), 
    child: const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.restaurant_menu, color: GalleryTheme.textSecondary, size: 32),
        SizedBox(height: 4),
        Text("Selasar Ruang Kitchen", style: TextStyle(color: GalleryTheme.textSecondary, fontSize: 11)),
      ],
    )
  );

  void _showDeleteDialog(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => CustomDeleteDialog(
        name: name,
        onConfirm: () {
          _deleteMenu(id);
        },
      ),
    );
  }
}

class CustomDeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onConfirm;

  const CustomDeleteDialog({super.key, required this.name, required this.onConfirm});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("Hapus Menu"),
      content: Text("Apakah kamu yakin ingin menghapus '$name' dari database katalog secara permanen?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal", style: TextStyle(color: Colors.grey))),
        TextButton(
          onPressed: () {
            onConfirm();
            Navigator.pop(context);
          }, 
          child: const Text("Hapus", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
        ),
      ],
    );
  }
}