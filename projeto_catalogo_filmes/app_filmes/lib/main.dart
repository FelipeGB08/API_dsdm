import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/catalogo_provider.dart';
import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => CatalogoProvider(),
      child: const AppFilmesApp(),
    ),
  );
}

class AppFilmesApp extends StatelessWidget {
  const AppFilmesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catálogo de Filmes e Séries',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const HomeScreen(),
    );
  }
}
