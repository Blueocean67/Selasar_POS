import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadMenuPage extends StatefulWidget {
  const UploadMenuPage({super.key});

  @override
  State<UploadMenuPage> createState() => _UploadMenuPageState();
}

class _UploadMenuPageState extends State<UploadMenuPage> {
  static const Color primaryGreen = Color(0xFF4A5D3F);
  static const Color accentGold = Color(0xFFBC8E5B);

  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();

  String selectedCategory = "Coffee";
  final List<String> categories = ["Coffee", "Non-Coffee", "Food", "Snack"];

  XFile? _pickedFile;
  bool _isLoading = false;

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery, 
        imageQuality: 35, // Gue turunin dikit biar gak berat di RAM HP lo
      );
      if (image != null) {
        setState(() => _pickedFile = image);
      }
    } catch (e) {
      _showSnackBar("Gagal ambil gambar: $e");
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim());

    if (_pickedFile == null || name.isEmpty || price == null) {
      _showSnackBar("⚠️ Data belum lengkap, Fad!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Baca file jadi bytes (Cara paling stabil buat Android)
      final bytes = await _pickedFile!.readAsBytes();
      final fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // 2. Upload ke Storage
      // Pastiin nama bucket lo 'menu-images' udah lo buat di dashboard
      await Supabase.instance.client.storage
          .from('menu-images')
          .uploadBinary(fileName, bytes);

      final String imageUrl = Supabase.instance.client.storage
          .from('menu-images')
          .getPublicUrl(fileName);

      // 3. Insert ke Database
      // Kolom disesuaiin sama info lo tadi 'image_url'
      await Supabase.instance.client.from('menus').insert({
        'name': name,
        'price': price,
        'category': selectedCategory,
        'description': _descController.text.trim(),
        'image_url': imageUrl, 
      });

      if (mounted) {
        _showSuccessDialog(name);
      }
    } catch (e) {
      debugPrint("Error Upload: $e");
      _showSnackBar("Gagal Upload: Periksa internet/kolom DB");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 16),
            Text("$name Berhasil Rilis!", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryGreen),
                onPressed: () {
                  Navigator.pop(context); // Tutup dialog
                  Navigator.pop(context); // Kembali ke dashboard
                },
                child: const Text("MANTAP", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String msg, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : primaryGreen,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9F2),
      appBar: AppBar(
        title: const Text("TAMBAH MENU BARU", style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPreviewSection(),
                const SizedBox(height: 30),
                _buildFormSection(),
                const SizedBox(height: 40),
                _buildSaveButton(),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator(color: primaryGreen)),
            ),
        ],
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 120,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                image: _pickedFile != null 
                  ? DecorationImage(image: FileImage(File(_pickedFile!.path)), fit: BoxFit.cover) 
                  : null,
              ),
              child: _pickedFile == null ? const Icon(Icons.camera_alt_outlined, color: primaryGreen) : null,
            ),
          ),
          const SizedBox(width: 15),
          const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("FOTO MENU", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text("Ketuk untuk ganti", style: TextStyle(fontSize: 12, color: primaryGreen)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      children: [
        _customField(_nameController, "Nama Menu", Icons.restaurant),
        const SizedBox(height: 15),
        _customField(_priceController, "Harga (IDR)", Icons.payments, isNumber: true),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
              onChanged: (v) => setState(() => selectedCategory = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _customField(TextEditingController ctrl, String label, IconData icon, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: primaryGreen),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: _isLoading ? null : _handleSave,
        child: const Text("SIMPAN KE DATABASE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }
}