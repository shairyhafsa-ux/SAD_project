import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_page.dart';
import 'single_item_page.dart';

class GridViewPage extends StatefulWidget {
  const GridViewPage({super.key});

  @override
  State<GridViewPage> createState() => _GridViewPageState();
}

class _GridViewPageState extends State<GridViewPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> cafeItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadCafeItems();
  }

  Future<void> loadCafeItems() async {
    try {
      final data = await supabase
          .from('cafe_items')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        cafeItems = data;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafe Menu Grid'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
              onPressed: () async {
                // Add Item button → opens UploadPage
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UploadPage()));
                loadCafeItems(); // reload after adding
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cafeItems.isEmpty
              ? const Center(child: Text('No items available'))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate:
                      const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: cafeItems.length,
                  itemBuilder: (context, index) {
                    final item = cafeItems[index];
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    SingleItemPage(item: item)));
                        loadCafeItems(); // reload after edit
                      },
                      child: Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: item['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS2zV6dfepwM77RWKJGm-h8J9Xdt05Zya6iTg&s'] != null
                                  ? ClipRRect(
                                      borderRadius: const BorderRadius.vertical(
                                          top: Radius.circular(16)),
                                      child: Image.network(
                                        item['https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTA3fWppS0PgONUPLLYBPb4y9pN7BuF2mE2RQ&s'],
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.local_cafe,
                                          size: 60, color: Colors.brown),
                                    ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'Iced Cappuccino',
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '৳ ${item['price'] ?? 350}',
                                    style: const TextStyle(
                                        color: Colors.brown,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

