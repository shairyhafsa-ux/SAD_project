import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _supabase = Supabase.instance.client;
  final _nameCtrl = TextEditingController();
  bool _saving = false;

  String? _avatarUrl;
  XFile? _pickedFile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _supabase
          .from('profiles')
          .select('username, avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data != null) {
        setState(() {
          _nameCtrl.text = (data['username'] ?? '').toString();
          _avatarUrl = data['avatar_url']?.toString();
        });
      }
    } catch (e) {
      _showSnack('Failed to load profile: $e');
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file != null) {
      setState(() => _pickedFile = file);
    }
  }

  Future<String?> _uploadAvatar(XFile file) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    final bytes = await file.readAsBytes();
    final path = '${user.id}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    try {
      await _supabase.storage.from('avatars').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final publicUrl = _supabase.storage.from('avatars').getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      _showSnack('Failed to upload avatar: $e');
      return null;
    }
  }

  Future<void> _save() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      String? avatarUrl = _avatarUrl;

      if (_pickedFile != null) {
        avatarUrl = await _uploadAvatar(_pickedFile!);
      }

      await _supabase.from('profiles').upsert({
        'id': user.id,
        'username': _nameCtrl.text.trim().isEmpty
            ? user.email?.split('@').first
            : _nameCtrl.text.trim(),
        'avatar_url': avatarUrl,
      });

      setState(() {
        _avatarUrl = avatarUrl;
        _pickedFile = null;
      });

      _showSnack('Profile updated');
    } catch (e) {
      _showSnack('Update failed: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = _pickedFile != null
        ? CircleAvatar(
            radius: 50,
            backgroundImage: FileImage(File(_pickedFile!.path)),
          )
        : (_avatarUrl == null || _avatarUrl!.isEmpty)
            ? CircleAvatar(
                radius: 50,
                backgroundColor: Colors.indigo.shade200,
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              )
            : CircleAvatar(
                radius: 50,
                backgroundImage: NetworkImage(_avatarUrl!),
              );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            Center(
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  avatarWidget,
                  IconButton(
                    tooltip: 'Change avatar',
                    onPressed: _pickImage,
                    icon: Container(
                      decoration: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(6),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'Display name',
                prefixIcon: const Icon(Icons.person_outline),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Save changes'),
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
