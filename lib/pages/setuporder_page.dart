import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupOrderPage extends StatefulWidget {
  const SetupOrderPage({super.key});

  @override
  State<SetupOrderPage> createState() => _SetupOrderPageState();
}

class _SetupOrderPageState extends State<SetupOrderPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color bgSurface = Color(0xFFF8F9F2);
  static const Color textDark = Color(0xFF2D3329);

  final TextEditingController _nameController = TextEditingController();
  int selectedTableIndex = -1;

  // LOGIKA OTOMATIS: Gambar & Saran Area Berdasarkan Waktu
  Map<String, dynamic> _getAutoRecommendation() {
    final hour = DateTime.now().hour;
    
    // PAGI (05:00 - 10:59)
    if (hour >= 5 && hour < 11) {
      return {
        "title": "Morning Sunshine",
        "desc": "Area Outdoor sejuk banget pagi ini. Pas buat ngopi santai. (Meja 01-05)",
        "img": "https://images.unsplash.com/photo-1559925393-8be0ec41b5ec?q=80&w=500&auto=format&fit=crop",
        "suggestedRange": [0, 1, 2, 3, 4]
      };
    } 
    // SIANG (11:00 - 14:59)
    else if (hour >= 11 && hour < 15) {
      return {
        "title": "Cool Indoor Zone",
        "desc": "Siang lagi terik, Meja 11-15 dekat AC paling nyaman buat makan siang.",
        "img": "https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=500&auto=format&fit=crop",
        "suggestedRange": [10, 11, 12, 13, 14]
      };
    } 
    // SORE (15:00 - 18:59)
    else if (hour >= 15 && hour < 19) {
      return {
        "title": "Relaxing Terrace",
        "desc": "Sore syahdu di area teras (Meja 06-10). Anginnya sepoi-sepoi.",
        "img": "https://images.unsplash.com/photo-1445116572660-236099ec97a0?q=80&w=500&auto=format&fit=crop",
        "suggestedRange": [5, 6, 7, 8, 9]
      };
    } 
    // MALAM (19:00 - 04:59)
    else {
      return {
        "title": "Evening Ambiance",
        "desc": "Rooftop (Meja 16-20) punya view lampu kota paling cantik malam ini.",
        "img": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=500&auto=format&fit=crop",
        "suggestedRange": [15, 16, 17, 18, 19]
      };
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reco = _getAutoRecommendation();

    return Scaffold(
      backgroundColor: bgSurface,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: bgSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: primaryGreen, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: const FlexibleSpaceBar(
              title: Text("Setup Pesanan", 
                style: TextStyle(color: textDark, fontWeight: FontWeight.w900, fontSize: 16)),
              centerTitle: true,
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  _buildSmartRecoCard(reco),
                  const SizedBox(height: 32),

                  _buildInputLabel("NAMA PEMESAN"),
                  _buildTextField(
                    controller: _nameController,
                    hint: "Siapa nama tamu kita?", 
                    icon: Icons.face_retouching_natural_rounded
                  ),
                  const SizedBox(height: 32),

                  _buildInputLabel("PILIH MEJA (20 UNIT)"),
                  _buildTableGrid(),
                  const SizedBox(height: 40),

                  _buildSubmitButton(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecoCard(Map<String, dynamic> reco) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() {
          // Klik kartu otomatis pilih meja pertama di jajaran saran
          selectedTableIndex = (reco['suggestedRange'] as List).first;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Area ${reco['title']} dipilih otomatis!"),
            backgroundColor: primaryGreen,
            duration: const Duration(milliseconds: 800),
          )
        );
      },
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
          border: Border.all(color: Colors.white),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                reco['img']!, 
                width: 85, height: 85, fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 85, height: 85, color: Colors.grey[200], child: const Icon(Icons.image_not_supported)
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                    child: const Text("SARAN AREA", style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: primaryGreen)),
                  ),
                  const SizedBox(height: 6),
                  Text(reco['title']!, style: const TextStyle(fontWeight: FontWeight.w900, color: textDark, fontSize: 15)),
                  const SizedBox(height: 4),
                  Text(reco['desc']!, style: const TextStyle(fontSize: 10, color: Colors.grey, height: 1.3)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(text, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: 1.2)),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String hint, required IconData icon}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.black26, fontWeight: FontWeight.normal),
          prefixIcon: Icon(icon, size: 22, color: primaryGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildTableGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: 20,
      itemBuilder: (context, index) {
        final isSelected = selectedTableIndex == index;
        // Simulasi meja penuh (meja 7 dan 12)
        bool isFull = (index == 6 || index == 11); 

        return InkWell(
          onTap: isFull ? null : () {
            HapticFeedback.lightImpact();
            setState(() => selectedTableIndex = index);
          },
          borderRadius: BorderRadius.circular(15),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isFull ? Colors.grey[200] : (isSelected ? primaryGreen : Colors.white),
              borderRadius: BorderRadius.circular(15),
              boxShadow: isSelected ? [BoxShadow(color: primaryGreen.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))] : [],
              border: Border.all(color: isSelected ? primaryGreen : Colors.transparent, width: 2),
            ),
            child: Center(
              child: Text(
                (index + 1).toString().padLeft(2, '0'),
                style: TextStyle(
                  color: isFull ? Colors.grey[400] : (isSelected ? Colors.white : textDark),
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    bool canSubmit = _nameController.text.isNotEmpty && selectedTableIndex != -1;

    return SizedBox(
      width: double.infinity,
      height: 65,
      child: ElevatedButton(
        onPressed: !canSubmit ? null : () {
          HapticFeedback.heavyImpact();
          // Navigasi ke menu utama
          Navigator.pushNamed(context, '/menu');
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: canSubmit ? 8 : 0,
          shadowColor: primaryGreen.withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(canSubmit ? "KONFIRMASI TEMPAT" : "LENGKAPI DATA", 
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1)),
            if (canSubmit) ...[
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            ]
          ],
        ),
      ),
    );
  }
}