import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalogo_models.dart';
import '../providers/catalogo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/titulo_card.dart';
import 'detalhes_titulo_screen.dart';

class FavoritosScreen extends StatelessWidget {
  const FavoritosScreen({super.key});

  Future<void> _abrirDetalhes(BuildContext context, TituloModel titulo) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DetalhesTituloScreen(titulo: titulo)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoritos')),
      body: SafeArea(
        child: Consumer<CatalogoProvider>(
          builder: (context, provider, _) {
            final titulos = provider.favoritos;
            if (provider.isLoading && titulos.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.accent),
              );
            }
            if (titulos.isEmpty) {
              return RefreshIndicator(
                color: AppTheme.accent,
                onRefresh: () async {
                  try {
                    await provider.carregarCatalogo();
                  } catch (_) {
                    // O erro já foi guardado pelo provider.
                  }
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    SizedBox(
                      height: MediaQuery.sizeOf(context).height * 0.72,
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite_border_rounded,
                                color: AppTheme.accentSecondary,
                                size: 56,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Ainda não há favoritos',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Toque no coração de um filme ou série para guardá-lo aqui.',
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                              if (provider.erro != null) ...[
                                const SizedBox(height: 12),
                                Text(
                                  provider.erro!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: AppTheme.accentSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppTheme.accent,
              onRefresh: () async {
                try {
                  await provider.carregarCatalogo();
                } catch (_) {
                  // O erro já foi guardado pelo provider.
                }
              },
              child: GridView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 230,
                  mainAxisExtent: 320,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: titulos.length,
                itemBuilder: (context, index) {
                  final titulo = titulos[index];
                  return TituloCard(
                    titulo: titulo,
                    onTap: () => _abrirDetalhes(context, titulo),
                    onFavoritePressed: () async {
                      try {
                        await provider.alternarFavorito(titulo.id);
                      } catch (_) {
                        // O erro fica disponível em provider.erro.
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
