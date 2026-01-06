import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme_provider.dart';
import 'ui/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Marron Motors',
            debugShowCheckedModeBanner: false,
            theme: themeProvider.themeData,
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
