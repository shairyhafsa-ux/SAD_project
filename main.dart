import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:PROJECTCODE/auth/auth_gate.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize( 
   url: 'https://jztoeqbvsawnzuvjgwfj.supabase.co',
   anonKey:'sb_publishable_5LiYQKk7qtKCQ88x9NTBqg_d09bKfR7'
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // theme: ThemeData.dark(),
      home: AuthGate(),
    );
  }
}

