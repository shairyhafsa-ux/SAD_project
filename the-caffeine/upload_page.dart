import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UploadPage extends StatefulWidget {
  const UploadPage({super.key});

  @override
  State<UploadPage> createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();

  File? selectedImage; // MARK IMAGE UPLOAD
  bool isLoading = false;

  Future<void> pickImage() async {
    final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) setState(() => selectedImage = File(picked.path));
  }

  Future<void> uploadItem() async {
    if (nameController.text.isEmpty ||
        priceController.text.isEmpty ||
        selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All fields are required')));
      return;
    }

    setState(() => isLoading = true);
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('cafe_images').upload(fileName, selectedImage!);
      final imageUrl = supabase.storage.from('cafe_images').getPublicUrl(fileName);

      await supabase.from('cafe_items').insert({
        'name': nameController.text,
        'price': int.parse(priceController.text),
        'image_url': imageUrl,
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Upload failed')));
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item'), backgroundColor: Colors.brown),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage, // CLICK HERE TO PICK IMAGE
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.brown.shade100,
                    borderRadius: BorderRadius.circular(16)),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(selectedImage!, fit: BoxFit.cover))
                    : const Center(
                        child: Icon(Icons.add_a_photo,
                            size: 40, color: Colors.brown),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                  labelText: 'Item Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                  labelText: 'Price', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: isLoading ? null : uploadItem,
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.brown, minimumSize: const Size(double.infinity, 50)),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Upload Item', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

