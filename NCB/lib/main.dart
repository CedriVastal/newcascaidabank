import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/balance_screen.dart';
import 'screens/transfer_screen.dart';
import 'screens/shop_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EddyTracker',
      theme: ThemeData.dark(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LoginScreen(),
        '/home': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return HomeScreen(username: args);
          } else {
            return const LoginScreen(); // fallback or error screen
          }
        },
        '/balance': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return BalanceScreen(username: args);
          } else {
            return const LoginScreen(); // fallback or error screen
          }
        },
        '/transfer': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return TransferScreen(username: args);
          } else {
            return const LoginScreen(); // fallback or error screen
          }
        },
        '/shop': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String) {
            return ShopScreen(username: args);
          } else {
            return const LoginScreen(); // fallback or error screen
          }
        },
      },
    );
  }
}