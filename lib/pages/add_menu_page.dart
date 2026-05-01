import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddMenuPage extends StatefulWidget {
  const AddMenuPage({super.key});

  @override
  State<AddMenuPage> createState() => _AddMenuPageState();
}

class _AddMenuPageState extends State<AddMenuPage> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  File? _imageFile; // Tempat nyimpen foto sementara

  // Fungsi Pilih Foto dari Gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  // Fungsi Upload & Simpan ke SQL
  Future<void> _saveMenu() async {
    if (_imageFile == null) return;

    // 1. Upload ke Storage
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage
        .from('menu-images')
        .upload(fileName, _imageFile!);

    // 2. Ambil Link Fotonya
    final imageUrl = Supabase.instance.client.storage
        .from('menu-images')
        .getPublicUrl(fileName);

    // 3. Simpan ke Tabel SQL Supabase
    await Supabase.instance.client.from('menus').insert({
      'name': _nameController.text,
      'price': int.parse(_priceController.text),
      'image_url': imageUrl,
    });

    Navigator.pop(context); // Balik ke halaman utama
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tambah Menu Selasar")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: _imageFile == null 
                ? Container(height: 150, color: Colors.grey[300], child: const Icon(Icons.add_a_photo))
                : Image.file(_imageFile!, height: 150),
            ),
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nama Menu")),
            TextField(controller: _priceController, decoration: const InputDecoration(labelText: "Harga"), keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _saveMenu, child: const Text("Simpan ke Cloud & SQL"))
          ],
        ),
      ),
    );
  }
}