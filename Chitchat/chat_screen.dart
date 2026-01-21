import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _supabase = Supabase.instance.client;
  final _msgCtrl = TextEditingController();
  final _listCtrl = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  final Map<String, Profile> _profiles = {}; 
  bool _sending = false;

  StreamSubscription<List<Map<String, dynamic>>>? _messagesSub;

  @override
  void initState() {
    super.initState();
    _subscribeMessages();
  }

  void _subscribeMessages() {
    _messagesSub = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at')
        .listen((data) async {
      setState(() {
        _messages = data;
      });

     
      if (_listCtrl.hasClients) {
        await Future.delayed(const Duration(milliseconds: 50));
        _listCtrl.jumpTo(_listCtrl.position.maxScrollExtent);
      }

      
      final missing = <String>{};
      for (final m in data) {
        final sid = m['sender_id']?.toString();
        if (sid != null && sid.isNotEmpty && !_profiles.containsKey(sid)) {
          missing.add(sid);
        }
      }
      if (missing.isNotEmpty) {
        await _fetchProfiles(missing.toList());
      }

      
      final me = _supabase.auth.currentUser?.id;
      if (me != null && !_profiles.containsKey(me)) {
        await _fetchProfiles([me]);
      }
    }, onError: (e) {
      _showSnack('Stream error: $e');
    });
  }

  Future<void> _fetchProfiles(List<String> ids) async {
    try {
      final res = await _supabase
          .from('profiles')
          .select('id, username, avatar_url, is_admin')
          .filter('id', 'in', ids);

      final map = <String, Profile>{};
      for (final p in (res as List)) {
        final prof = Profile.fromJson(p as Map<String, dynamic>);
        map[prof.id] = prof;
      }

      setState(() {
        _profiles.addAll(map);
      });
    } catch (e) {
      _showSnack('Failed to fetch profiles: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgCtrl.text.trim();
    final user = _supabase.auth.currentUser;

    if (text.isEmpty || user == null) return;

    setState(() => _sending = true);
    try {
      await _supabase.from('messages').insert({
        'sender_id': user.id,
        'text': text,
      });
      _msgCtrl.clear();
    } catch (e) {
      _showSnack('Failed to send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _editMessage({
    required String id,
    required String originalText,
  }) async {
    final ctrl = TextEditingController(text: originalText);
    final updated = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Edit message'),
          content: TextField(
            controller: ctrl,
            maxLines: null,
            decoration: const InputDecoration(
              hintText: 'Update your message',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (updated == null) return;
    if (updated.isEmpty || updated == originalText) return;

    try {
      await _supabase.from('messages').update({'text': updated}).eq('id', id);
      _showSnack('Message updated');
    } catch (e) {
      _showSnack('Update failed: $e');
    }
  }

  Future<void> _deleteMessage(String id) async {
    try {
      await _supabase.from('messages').delete().eq('id', id);
      _showSnack('Message deleted');
    } catch (e) {
      _showSnack('Delete failed: $e');
    }
  }

  Future<bool> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await _deleteMessage(id);
      return true;
    }
    return false;
  }

  Future<void> _signOut() async {
    try {
      await _supabase.auth.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/auth');
    } catch (e) {
      _showSnack('Sign out failed: $e');
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _messagesSub?.cancel();
    _msgCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _supabase.auth.currentUser;
    final df = DateFormat('MMM d, hh:mm a'); 
    final myProfile = user == null ? null : _profiles[user.id];
    final isAdmin = myProfile?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: () => Navigator.pushNamed(context, '/profile'),
            icon: const Icon(Icons.person),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? const Center(
                    child: Text(
                      'No messages yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    controller: _listCtrl,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final id = (msg['id'] ?? '').toString();
                      final senderId = msg['sender_id']?.toString() ?? '';
                      final isMe = user?.id == senderId;
                      final text = (msg['text'] ?? '').toString();

                     
                      final createdAt = msg['created_at'];
                      String tsStr = '';
                      if (createdAt != null) {
                        try {
                          final dt = createdAt is DateTime
                              ? createdAt
                              : DateTime.parse(createdAt.toString());
                          tsStr = df.format(dt);
                        } catch (_) {
                          tsStr = createdAt.toString();
                        }
                      }

                      final profile = _profiles[senderId];
                      final username = profile?.username ?? 'User';
                      final avatarUrl = profile?.avatarUrl;

                      final canEdit = isMe; 
                      final canDelete = isMe || isAdmin; 

                      final bubble = _MessageBubble(
                        text: text,
                        username: username,
                        avatarUrl: avatarUrl,
                        timestamp: tsStr,
                        isMe: isMe,
                        menuBuilder: () {
                          return PopupMenuButton<_MsgAction>(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            onSelected: (action) async {
                              if (action == _MsgAction.edit && canEdit) {
                                await _editMessage(id: id, originalText: text);
                              } else if (action == _MsgAction.delete && canDelete) {
                                await _confirmDelete(id);
                              }
                            },
                            itemBuilder: (context) {
                              return <PopupMenuEntry<_MsgAction>>[
                                if (canEdit)
                                  const PopupMenuItem(
                                    value: _MsgAction.edit,
                                    child: Text('Edit'),
                                  ),
                                if (canDelete)
                                  const PopupMenuItem(
                                    value: _MsgAction.delete,
                                    child: Text('Delete'),
                                  ),
                              ];
                            },
                            child: const Icon(Icons.more_vert, size: 18),
                          );
                        },
                      );

                      
                      if (canDelete && isMe) {
                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            color: Colors.red.shade300,
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (_) => _confirmDelete(id),
                          onDismissed: (_) {},
                          child: bubble,
                        );
                      }

                      return bubble;
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12).copyWith(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _sending ? null : _sendMessage,
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}

enum _MsgAction { edit, delete }

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.username,
    required this.avatarUrl,
    required this.timestamp,
    required this.isMe,
    required this.menuBuilder,
  });

  final String text;
  final String username;
  final String? avatarUrl;
  final String timestamp;
  final bool isMe;
  final Widget Function() menuBuilder;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = isMe ? Colors.indigo.shade200 : Colors.grey.shade300;

    final radius = BorderRadius.only(
      topLeft: const Radius.circular(14),
      topRight: const Radius.circular(14),
      bottomLeft: Radius.circular(isMe ? 14 : 6),
      bottomRight: Radius.circular(isMe ? 6 : 14),
    );

    final avatar = avatarUrl == null || avatarUrl!.isEmpty
        ? CircleAvatar(
            radius: 16,
            backgroundColor: Colors.indigo.shade400,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          )
        : CircleAvatar(
            radius: 16,
            backgroundImage: NetworkImage(avatarUrl!),
          );

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      constraints:
          BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  username,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              menuBuilder(),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            text,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(
            timestamp,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) avatar,
          if (!isMe) const SizedBox(width: 8),
          bubble,
          if (isMe) const SizedBox(width: 8),
          if (isMe) avatar,
        ],
      ),
    );
  }
}

class Profile {
  final String id;
  final String username;
  final String? avatarUrl;
  final bool isAdmin;

  Profile({
    required this.id,
    required this.username,
    this.avatarUrl,
    this.isAdmin = false,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id']?.toString() ?? '',
      username: (json['username'] ?? 'User').toString(),
      avatarUrl: json['avatar_url']?.toString(),
      isAdmin: (json['is_admin'] ?? false) == true,
    );
  }
}
