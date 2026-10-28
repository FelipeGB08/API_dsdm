import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

void main() {
  runApp(const AppFilmesApp());
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
      home: const _InicioScreen(),
    );
  }
}

class _InicioScreen extends StatelessWidget {
  const _InicioScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catálogo')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_movies_outlined, size: 56),
              const SizedBox(height: 16),
              Text(
                'Filmes e séries',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'A base visual do aplicativo está pronta para conectar à API.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
