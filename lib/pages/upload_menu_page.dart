import 'package:flutter/material.dart';

class UploadMenuPage extends StatefulWidget {
  const UploadMenuPage({super.key});

  @override
  State<UploadMenuPage> createState() => _UploadMenuPageState();
}

class _UploadMenuPageState extends State<UploadMenuPage> {
  String selectedCategory = "Coffee";
  final List<String> categories = ["Coffee", "Non-Coffee", "Food", "Snack"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF4A5D3F)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah Menu Baru",
          style: TextStyle(color: Color(0xFF2D3329), fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Area Upload Gambar (Placeholder UI)
            Center(
              child: GestureDetector(
                onTap: () {
                  // Logika pilih gambar dari galeri HP
                },
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF4A5D3F).withOpacity(0.2), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFF4A5D3F)),
                      const SizedBox(height: 12),
                      Text("Ketuk untuk Upload Foto", 
                        style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      const Text("Format: JPG, PNG (Max 5MB)", 
                        style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Form Input
            _buildInputLabel("NAMA MENU"),
            _buildTextField("Contoh: Caramel Macchiato"),
            
            const SizedBox(height: 20),
            _buildInputLabel("HARGA (RP)"),
            _buildTextField("Contoh: 25000", isNumber: true),
            
            const SizedBox(height: 20),
            _buildInputLabel("KATEGORI"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedCategory,
                  isExpanded: true,
                  items: categories.map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      selectedCategory = newValue!;
                    });
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            _buildInputLabel("DESKRIPSI (OPSIONAL)"),
            _buildTextField("Ceritakan sedikit tentang rasa menu ini...", maxLines: 3),
            
            const SizedBox(height: 40),

            // Tombol Simpan
            ElevatedButton(
              onPressed: () {
                // Logika simpan ke database/list
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Menu Berhasil Ditambahkan!")),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A5D3F),
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("SIMPAN MENU", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF4A5D3F))),
    );
  }

  Widget _buildTextField(String hint, {bool isNumber = false, int maxLines = 1}) {
    return TextField(
      maxLines: maxLines,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
      ),
    );
  }
}