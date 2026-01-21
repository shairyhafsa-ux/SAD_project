import 'package:chitchat/Screens/auth_screen.dart';
import 'package:chitchat/Screens/chat_screen.dart';
import 'package:chitchat/Screens/profile_screen.dart';
import 'package:chitchat/Screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://cxlfqfjvenvbvxcluwbx.supabase.co',
    anonKey: 'sb_publishable_AbzFl4AZmCKdPl_LbfwenA_1GNHaQ80',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChitChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A00E0),
          brightness: Brightness.light,
          primary: const Color(0xFF4A00E0),
          secondary: const Color(0xFF8E2DE2),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            height: 1.4,
          ),
          displayLarge: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 48,
            color: Colors.white,
          ),
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 2,
          backgroundColor: Colors.white,
          foregroundColor: Color(0xFF4A00E0),
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A00E0),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF4A00E0), width: 2),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4A00E0),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF4A00E0),
        ),
      ),
      home: const SplashScreen(),
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/auth': (_) => const AuthScreen(),
        '/chat': (_) => const ChatScreen(),
        '/profile': (_) => const ProfileScreen(),
      },
    );
  }
}
