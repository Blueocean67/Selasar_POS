import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupOrderPage extends StatefulWidget {
  const SetupOrderPage({super.key});

  @override
  State<SetupOrderPage> createState() => _SetupOrderPageState();
}

class _SetupOrderPageState extends State<SetupOrderPage> {
  static const Color primaryGreen = Color(0xFF556B2F);
  static const Color softOlive = Color(0xFFAAB36B);
  static const Color bgSurface = Color(0xFFFDFDF9);
  static const Color textDark = Color(0xFF2D3329);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cashierController = TextEditingController();
  
  int selectedTableIndex = -1;
  String? _avatarUrl; 
  List<int> occupiedTables = [5, 10, 14]; 
  int totalOrdersToday = 42;
  Timer? _liveSimulationTimer;

  User? get user => Supabase.instance.client.auth.currentUser;

  @override
  void initState() {
    super.initState();
    _loadCashierProfile();
    _startLiveDemoSimulation();
  }

  Future<void> _loadCashierProfile() async {
    try {
      final userId = user?.id;
      if (userId != null) {
        final data = await Supabase.instance.client
            .from('profiles')
            .select('full_name, avatar_url')
            .eq('id', userId)
            .maybeSingle();

        if (data != null && mounted) {
          setState(() {
            _cashierController.text = data['full_name'] ?? "Staff Selasar";
            _avatarUrl = data['avatar_url'];
          });
        }
      }
    } catch (e) {
      debugPrint("Gagal memuat profil: $e");
    }
  }

  void _startLiveDemoSimulation() {
    _liveSimulationTimer = Timer.periodic(const Duration(seconds: 7), (timer) {
      if (!mounted) return;
      
      final random = Random();
      setState(() {
        // 1. Simulasi meja kosong ditinggal pelanggan (Selesai bayar)
        if (occupiedTables.isNotEmpty && random.nextBool()) {
          int indexToRemove = random.nextInt(occupiedTables.length);
          int tableFreed = occupiedTables[indexToRemove];
          if (tableFreed != selectedTableIndex) {
            occupiedTables.remove(tableFreed);
          }
        }
        
        // 2. Simulasi pelanggan baru datang memesan meja acak secara live
        if (occupiedTables.length < 12 && random.nextBool()) {
          int newTable = random.nextInt(20);
          if (!occupiedTables.contains(newTable) && newTable != selectedTableIndex) {
            occupiedTables.add(newTable);
            totalOrdersToday++;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _cashierController.dispose();
    _liveSimulationTimer?.cancel();
    super.dispose();
  }

  // Fungsi untuk handle klik meja
  void _handleTableTap(int index) {
    setState(() {
      if (occupiedTables.contains(index)) {
        // Jika meja terisi, klik akan mengosongkannya (Reset/Simulasi Selesai Makan)
        occupiedTables.remove(index);
        if (selectedTableIndex == index) selectedTableIndex = -1;
      } else {
        // Jika meja kosong, pilih meja tersebut
        selectedTableIndex = index;
      }
    });
  }

  // Fungsi Rekomendasi berdasarkan waktu yang ter-refresh otomatis
  Map<String, dynamic> _getAutoRecommendation() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) {
      return {
        "title": "Morning Ambience",
        "desc": "Cahaya matahari masuk sempurna. Area dekat jendela (Window Seat) sangat disarankan.",
        "img": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?auto=format&fit=crop&q=80&w=300",
      };
    } else if (hour >= 11 && hour < 17) {
      return {
        "title": "Afternoon Vibe",
        "desc": "Area Indoor AC paling nyaman untuk bekerja atau makan siang santai.",
        "img": "https://images.unsplash.com/photo-1445116572660-236099ec97a0?auto=format&fit=crop&q=80&w=300",
      };
    } else if (hour >= 17 && hour < 20) {
      return {
        "title": "Evening Ambiance",
        "desc": "Lampu temaram mulai aktif. Area outdoor/teras cocok untuk menikmati senja.",
        "img": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?auto=format&fit=crop&q=80&w=300",
      };
    } else {
      return {
        "title": "Night Sanctuary",
        "desc": "Suasana tenang dengan musik jazz. Pojok sofa (Corner Seat) paling favorit.",
        "img": "https://images.unsplash.com/photo-1504675099198-7023dd85f5a3?auto=format&fit=crop&q=80&w=300",
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    final reco = _getAutoRecommendation();

    return Scaffold(
      backgroundColor: bgSurface,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: bgSurface,
        elevation: 0,
        iconTheme: const IconThemeData(color: textDark),
        title: const Text("Selasar Ruang", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/profile').then((_) => _loadCashierProfile()),
              child: CircleAvatar(
                radius: 18, 
                backgroundColor: const Color(0xFFF1F1E6),
                backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                child: _avatarUrl == null ? const Icon(Icons.person, size: 18, color: primaryGreen) : null,
              ),
            ),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("NEW TRANSACTION", style: TextStyle(color: softOlive, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1.2)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      const Icon(Icons.trending_up, color: primaryGreen, size: 12),
                      const SizedBox(width: 4),
                      Text("Live Order: $totalOrdersToday", style: const TextStyle(color: primaryGreen, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              ],
            ),
            const SizedBox(height: 8),
            const Text("Setup Your Order\nInfo", style: TextStyle(color: textDark, fontWeight: FontWeight.bold, fontSize: 32, height: 1.1)),
            const SizedBox(height: 12),
            const Text("Siapkan tempat terbaik untuk tamu kita. Pastikan nomor meja sesuai dengan ketersediaan.", style: TextStyle(color: Colors.grey, fontSize: 14)),
            const SizedBox(height: 30),
            
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 20, offset: const Offset(0, 10))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInputLabel("Nama Staff"),
                  TextField(
                    controller: _cashierController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: "Input Nama ",
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                      filled: true,
                      fillColor: bgSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel("NAMA PEMESAN"),
                  TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: "Masukkan nama tamu",
                      prefixIcon: const Icon(Icons.person_outline, size: 20),
                      filled: true,
                      fillColor: bgSurface,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInputLabel("NOMOR MEJA (Klik untuk Pilih/Kosongkan)"),
                  _buildTableGrid(),
                  const SizedBox(height: 30),
                  _buildSubmitButton(),
                ],
              ),
            ),
            
            const SizedBox(height: 30),
            _buildAmbienceCard(reco),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: primaryGreen),
            accountName: Text(_cashierController.text.toUpperCase()),
            accountEmail: Text(user?.email ?? "selasar@coffee.com"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white24,
              backgroundImage: _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
              child: _avatarUrl == null ? const Icon(Icons.store, color: Colors.white, size: 32) : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text("Dashboard"),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text("History Transaksi"),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/history');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text("Keluar", style: TextStyle(color: Colors.red)),
            onTap: () async {
              try {
                await Supabase.instance.client.auth.signOut();
              } catch (_) {}
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textDark, letterSpacing: 0.5)),
    );
  }

  Widget _buildTableGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.3,
      ),
      itemCount: 20,
      itemBuilder: (_, index) {
        final isFull = occupiedTables.contains(index);
        final isSelected = selectedTableIndex == index;

        return InkWell(
          onTap: () => _handleTableTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isFull ? Colors.red.withOpacity(0.15) : (isSelected ? primaryGreen : bgSurface),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isFull ? Colors.red.shade300 : (isSelected ? primaryGreen : Colors.grey.shade200),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                    color: isSelected ? Colors.white : (isFull ? Colors.red : textDark),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isFull)
                  const Text("TERISI", style: TextStyle(fontSize: 8, color: Colors.red, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    bool isActive = _nameController.text.trim().isNotEmpty && 
                   _cashierController.text.trim().isNotEmpty && 
                   selectedTableIndex != -1 && 
                   !occupiedTables.contains(selectedTableIndex);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isActive ? () {
          final String customerName = _nameController.text.trim();
          final String typedCashierName = _cashierController.text.trim(); 
          final int tableNumber = selectedTableIndex + 1;

          setState(() {
            occupiedTables.add(selectedTableIndex);
          });

          Navigator.pushNamed(
            context, 
            '/menu', 
            arguments: {
              'customer_name': customerName,
              'table_number': tableNumber,
              'cashier_name': typedCashierName,
              'avatar_url': _avatarUrl, // Sekarang avatar_url ikut terkirim ke halaman menu
            },
          ).then((_) {
            setState(() {
              _nameController.clear();
              selectedTableIndex = -1;
            });
          });
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          disabledBackgroundColor: Colors.grey.shade300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text("Mulai Pesanan", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            SizedBox(width: 8),
            Icon(Icons.arrow_forward, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbienceCard(Map<String, dynamic> reco) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1E6),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reco['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryGreen)),
                const SizedBox(height: 4),
                Text(reco['desc'], style: const TextStyle(fontSize: 11, color: Colors.black54, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              reco['img'], 
              width: 85, 
              height: 85, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 85, 
                height: 85, 
                color: Colors.grey[300],
                child: const Icon(Icons.broken_image, color: Colors.grey),
              ),
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return Container(width: 85, height: 85, color: Colors.grey[300]);
              },
            ),
          )
        ],
      ),
    );
  }
}