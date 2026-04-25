import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/cart_provider.dart';
import 'providers/theme_provider.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: const ShopZoneApp(),
    ),
  );
}

class ShopZoneApp extends StatelessWidget {
  const ShopZoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    return MaterialApp(
      title: 'ShopZone',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.theme,
      home: const LoginScreen(),
    );
  }
}