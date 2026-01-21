import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final _supabase = Supabase.instance.client;

  late final TabController _tabController;

  final _loginEmailCtrl = TextEditingController();
  final _loginPassCtrl = TextEditingController();

  final _signupEmailCtrl = TextEditingController();
  final _signupPassCtrl = TextEditingController();
  final _signupNameCtrl = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _supabase.auth.onAuthStateChange.listen((event) {
      final session = event.session;
      if (session != null && mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginEmailCtrl.dispose();
    _loginPassCtrl.dispose();
    _signupEmailCtrl.dispose();
    _signupPassCtrl.dispose();
    _signupNameCtrl.dispose();
    super.dispose();
  }

  
  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _loginEmailCtrl.text.trim();
      final password = _loginPassCtrl.text.trim();

      
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Enter a valid email address.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      await _supabase.auth.signInWithPassword(email: email, password: password);
      
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

 
  Future<void> _signup() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _signupEmailCtrl.text.trim();
      final password = _signupPassCtrl.text.trim();
      final displayName = _signupNameCtrl.text.trim();

    
      if (email.isEmpty || password.isEmpty) {
        throw Exception('Email and password are required.');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Enter a valid email address.');
      }
      if (password.length < 6) {
        throw Exception('Password must be at least 6 characters.');
      }

      final res = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {
          'display_name': displayName,
        },
      );

      final user = _supabase.auth.currentUser;
      final session = res.session;

      if (user != null) {
        final username =
            displayName.isNotEmpty ? displayName : email.split('@').first;

        await _supabase.from('profiles').upsert({
          'id': user.id,
          'username': username,
          'avatar_url': null,
        });
      }

      if (session == null) {
        _showSnack('Signup successful. Please confirm your email to continue.');
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

 
  Future<void> _resetPassword() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final email = (_tabController.index == 0
              ? _loginEmailCtrl.text
              : _signupEmailCtrl.text)
          .trim();

      if (email.isEmpty) {
        throw Exception('Enter your email to reset password.');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Enter a valid email address.');
      }

      await _supabase.auth.resetPasswordForEmail(email);
      _showSnack('Password reset email sent.');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _loading = false);
    }
  }

  
  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

 
  @override
  Widget build(BuildContext context) {
    final loading = _loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome to ChatApp'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(icon: Icon(Icons.login), text: 'Login'),
            Tab(icon: Icon(Icons.person_add), text: 'Sign up'),
          ],
        ),
      ),
      body: AbsorbPointer(
        absorbing: loading,
        child: Stack(
          children: [
            TabBarView(
              controller: _tabController,
              children: [
                _LoginTab(
                  emailCtrl: _loginEmailCtrl,
                  passCtrl: _loginPassCtrl,
                  onLogin: _login,
                  onReset: _resetPassword,
                ),
                _SignupTab(
                  emailCtrl: _signupEmailCtrl,
                  passCtrl: _signupPassCtrl,
                  nameCtrl: _signupNameCtrl,
                  onSignup: _signup,
                  onReset: _resetPassword,
                ),
              ],
            ),
            if (loading)
              Container(
                color: Colors.black.withOpacity(0.2),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: _error == null
          ? null
          : Container(
              color: Colors.red.shade50,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

// ================= LOGIN TAB =================
class _LoginTab extends StatelessWidget {
  const _LoginTab({
    required this.emailCtrl,
    required this.passCtrl,
    required this.onLogin,
    required this.onReset,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final VoidCallback onLogin;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text(
            'Welcome back 👋',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onLogin,
            icon: const Icon(Icons.login),
            label: const Text('Login'),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}


class _SignupTab extends StatelessWidget {
  const _SignupTab({
    required this.emailCtrl,
    required this.passCtrl,
    required this.nameCtrl,
    required this.onSignup,
    required this.onReset,
  });

  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final TextEditingController nameCtrl;
  final VoidCallback onSignup;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: ListView(
        children: [
          const Text(
            'Create your account ✨',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Display name (optional)',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: passCtrl,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Password',
              prefixIcon: Icon(Icons.lock_outline),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onSignup,
            icon: const Icon(Icons.person_add),
            label: const Text('Sign up'),
          ),
          TextButton.icon(
            onPressed: onReset,
            icon: const Icon(Icons.refresh),
            label: const Text('Forgot password?'),
          ),
        ],
      ),
    );
  }
}
