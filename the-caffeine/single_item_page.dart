import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SingleItemPage extends StatefulWidget {
  final Map<String, dynamic> item;
  const SingleItemPage({super.key, required this.item});

  @override
  State<SingleItemPage> createState() => _SingleItemPageState();
}

class _SingleItemPageState extends State<SingleItemPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController descController;

  File? selectedImage;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.item['name']);
    priceController =
        TextEditingController(text: widget.item['price'].toString());
    descController =
        TextEditingController(text: widget.item['description'] ?? '');
  }

  Future<void> pickImage() async {
    final picked =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<void> updateItem() async {
    setState(() => isLoading = true);

    String? imageUrl = widget.item['image_url'];

    if (selectedImage != null) {
      final fileName = 'item_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await supabase.storage.from('cafe_images').upload(fileName, selectedImage!);
      imageUrl = supabase.storage.from('cafe_images').getPublicUrl(fileName);
    }

    await supabase.from('cafe_items').update({
      'name': nameController.text,
      'price': int.parse(priceController.text),
      'description': descController.text,
      'image_url': imageUrl,
    }).eq('id', widget.item['id']);

    if (mounted) Navigator.pop(context);
  }

  Future<void> deleteItem() async {
    await supabase.from('cafe_items').delete().eq('id', widget.item['id']);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Item Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.brown.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(selectedImage!, fit: BoxFit.cover),
                      )
                    : widget.item['image_url'] != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(widget.item['image_url'],
                                fit: BoxFit.cover),
                          )
                        : const Center(
                            child: Icon(Icons.local_cafe, size: 60, color: Colors.brown),
                          ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : updateItem,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.brown),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Update'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: deleteItem,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

