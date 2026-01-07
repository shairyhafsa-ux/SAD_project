import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  final ImagePicker picker = ImagePicker();

  File? profileImage; // MARK IMAGE UPLOAD AREA
  bool isLoading = false;

  Future<void> pickProfileImage() async {
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => profileImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile'), backgroundColor: Colors.brown),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickProfileImage, // CLICK TO PICK IMAGE
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.brown.shade100,
                backgroundImage:
                    profileImage != null ? FileImage(profileImage!) : null,
                child: profileImage == null
                    ? const Icon(Icons.person, size: 60, color: Colors.brown)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            const Text('Guest User',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

