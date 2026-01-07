import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'upload_page.dart';
import 'single_item_page.dart';

class ListViewPage extends StatefulWidget {
  const ListViewPage({super.key});

  @override
  State<ListViewPage> createState() => _ListViewPageState();
}

class _ListViewPageState extends State<ListViewPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<dynamic> cafeItems = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
  }

  Future<void> fetchItems() async {
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

  Future<void> deleteItem(int id) async {
    await supabase.from('cafe_items').delete().eq('id', id);
    fetchItems();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cafe Items List'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const UploadPage()));
                fetchItems(); // reload after adding
              },
              icon: const Icon(Icons.add))
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : cafeItems.isEmpty
              ? const Center(child: Text('No items found'))
              : ListView.builder(
                  itemCount: cafeItems.length,
                  itemBuilder: (context, index) {
                    final item = cafeItems[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: item['image_url'] != null
                            ? CircleAvatar(
                                backgroundImage:
                                    NetworkImage(item['image_url']),
                              )
                            : const CircleAvatar(
                                child: Icon(Icons.local_cafe),
                              ),
                        title: Text(item['name'] ?? ''),
                        subtitle: Text('৳ ${item['price']}'),
                        trailing: IconButton(
                          icon:
                              const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => deleteItem(item['id']),
                        ),
                        onTap: () async {
                          await Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      SingleItemPage(item: item)));
                          fetchItems(); // reload after edit
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

