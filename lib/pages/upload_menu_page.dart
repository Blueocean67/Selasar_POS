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
  // ── PALETTE ─────────────────────────────────────────────────
  static const Color primaryGreen = Color(0xFF556B2F);
  static const Color bgCream      = Color(0xFFFDFDF9);
  static const Color textDark     = Color(0xFF2D3329);
  static const Color softGrey     = Color(0xFFF1F1E6);

  final _nameController  = TextEditingController();
  final _priceController = TextEditingController();
  final _descController  = TextEditingController();

  // ── STATE ────────────────────────────────────────────────────
  String selectedCategory = "Coffee";
  final List<String> categories = ["Coffee", "Non-Coffee", "Food", "Snack"];

  bool isVisibleInMenu  = true;
  bool isLimitedStock   = false;

  XFile? _pickedFile;
  bool   _isLoading = false;

  // ── LIFECYCLE ────────────────────────────────────────────────
  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── IMAGE PICKER ─────────────────────────────────────────────
  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 45, 
      );
      if (image != null && mounted) {
        setState(() => _pickedFile = image);
      }
    } catch (e) {
      _showSnackBar("Gagal ambil gambar: $e");
    }
  }

  Future<void> _handleSave() async {
    // --- (a) VALIDASI ---
    final String name     = _nameController.text.trim();
    final String priceStr = _priceController.text.trim();
    final int?   price    = int.tryParse(priceStr);

    if (name.isEmpty) {
      _showSnackBar("⚠️ Nama produk tidak boleh kosong");
      return;
    }
    if (priceStr.isEmpty || price == null || price < 0) {
      _showSnackBar("⚠️ Harga harus berupa angka valid (≥ 0)");
      return;
    }
    if (_pickedFile == null) {
      _showSnackBar("⚠️ Harap pilih foto produk terlebih dahulu");
      return;
    }
    if (selectedCategory.isEmpty) {
      _showSnackBar("⚠️ Pilih kategori produk");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // --- (b) UPLOAD GAMBAR KE SUPABASE STORAGE ───
      final String fileExt = _pickedFile!.path.split('.').last.toLowerCase();
      final String fileName = 'menu_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final File imageFile = File(_pickedFile!.path);

      await Supabase.instance.client.storage
          .from('menu-images')
          .upload(
            fileName,
            imageFile,
            fileOptions: FileOptions(
              contentType: 'image/$fileExt',
              cacheControl: '3600',
              upsert: false,
            ),
          );

      // Ambil Public URL resmi setelah berkas terupload ke bucket
      final String imageUrl = Supabase.instance.client.storage
          .from('menu-images')
          .getPublicUrl(fileName);

      // --- (c) CLEAN PAYLOAD: Sesuai struktur standar skema SQL Supabase ---
      final Map<String, dynamic> insertPayload = {
        'name': name,
        'price': price,
        'category': selectedCategory,
        'stock': isLimitedStock ? 10 : 9999,
        'image_url': imageUrl, // Hanya gunakan satu struktur nama kolom standar generic POS
        'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      };

      await Supabase.instance.client.from('menus').insert(insertPayload);

      // --- (d) BERHASIL ---
      if (mounted) {
        _resetForm();
        _showSuccessDialog(name);
      }
    } on StorageException catch (e) {
      debugPrint('[Storage Error] ${e.message}');
      if (mounted) _showSnackBar("Gagal upload foto ke Storage: ${e.message}");
    } on PostgrestException catch (e) {
      debugPrint('[DB Error] ${e.message}');
      if (mounted) {
        _showSnackBar("Gagal menyimpan ke database Supabase. Periksa kembali struktur kolom tabel menus Anda.");
      }
    } catch (e) {
      debugPrint('[Unexpected Error] $e');
      if (mounted) _showSnackBar("Terjadi kesalahan tidak terduga: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── FORM RESET ───────────────────────────────────────────────
  void _resetForm() {
    _nameController.clear();
    _priceController.clear();
    _descController.clear();
    setState(() {
      _pickedFile        = null;
      selectedCategory   = "Coffee";
      isVisibleInMenu    = true;
      isLimitedStock     = false;
    });
  }

  // ── BUILD ────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: textDark, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Tambah / Edit Menu",
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImageUploadCard(),
                const SizedBox(height: 20),
                _buildFormCard(),
                const SizedBox(height: 20),
                _buildSettingsCard(),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(color: primaryGreen),
              ),
            ),
        ],
      ),
    );
  }

  // ── WIDGETS ──────────────────────────────────────────────────

  Widget _buildImageUploadCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: softGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Foto Produk",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: _isLoading ? null : _pickImage,
            child: Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: _pickedFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.file(
                        File(_pickedFile!.path),
                        fit: BoxFit.cover,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          color: primaryGreen.withOpacity(0.5),
                          size: 36,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Upload Foto Menu",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "JPG, PNG atau WEBP (Maks. 2MB).",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 20,
          )
        ],
      ),
      child: Column(
        children: [
          _buildMinimalField(
            _nameController,
            "Nama Produk",
            "e.g. Pizza Mozarella",
          ),
          const SizedBox(height: 20),
          _buildMinimalField(
            _priceController,
            "Harga (IDR)",
            "Rp 0",
            isNumber: true,
          ),
          const SizedBox(height: 20),
          _buildCategoryDropdown(),
          const SizedBox(height: 20),
          _buildMinimalField(
            _descController,
            "Deskripsi Produk (Opsional)",
            "Ceritakan profil rasa atau keunikan menu ini...",
            isLongText: true,
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalField(
    TextEditingController ctrl,
    String label,
    String hint, {
    bool isNumber   = false,
    bool isLongText = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: isLongText ? 3 : 1,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          enabled: !_isLoading,
          style: const TextStyle(fontSize: 14, color: textDark),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
            filled: true,
            fillColor: softGrey.withOpacity(0.4),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Kategori",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textDark),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: softGrey.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              onChanged: _isLoading
                  ? null
                  : (v) {
                      if (v != null) setState(() => selectedCategory = v);
                    },
              items: categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 13, color: textDark)),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        children: [
          _buildSwitchRow(
            "Tampilkan di Menu",
            "Aktifkan agar menu muncul di POS",
            isVisibleInMenu,
            (v) => setState(() => isVisibleInMenu = v),
          ),
          const Divider(height: 32),
          _buildSwitchRow(
            "Stok Terbatas",
            "Lacak ketersediaan harian",
            isLimitedStock,
            (v) => setState(() => isLimitedStock = v),
          ),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "BATAL",
                    style: TextStyle(
                      color: Colors.grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAAB36C),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "SIMPAN",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(
    String title,
    String sub,
    bool val,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                sub,
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
        Switch(
          value: val,
          onChanged: _isLoading ? null : onChanged,
          activeColor: primaryGreen,
        ),
      ],
    );
  }

  // ── FEEDBACK HELPERS ─────────────────────────────────────────

  void _showSnackBar(String msg, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : primaryGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showSuccessDialog(String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: primaryGreen, size: 60),
            const SizedBox(height: 16),
            Text(
              "$name Berhasil Ditambahkan",
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext); 
                Navigator.pop(context, true); 
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
              ),
              child: const Text(
                "Selesai",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}