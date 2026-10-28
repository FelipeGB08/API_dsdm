import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalogo_models.dart';
import '../providers/catalogo_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/titulo_card.dart';
import 'detalhes_titulo_screen.dart';
import 'favoritos_screen.dart';
import 'formulario_titulo_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<CatalogoProvider>();
      if (provider.titulos.isEmpty && !provider.isLoading) {
        provider.carregarDados().catchError((_) {});
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _abrirCadastro() async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const FormularioTituloScreen()),
    );
  }

  Future<void> _abrirDetalhes(TituloModel titulo) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => DetalhesTituloScreen(titulo: titulo)),
    );
  }

  Future<void> _abrirFavoritos() async {
    await Navigator.of(
      context,
    ).push<void>(MaterialPageRoute(builder: (_) => const FavoritosScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo'),
        actions: [
          IconButton(
            tooltip: 'Favoritos',
            onPressed: _abrirFavoritos,
            icon: const Icon(Icons.favorite_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                controller: _searchController,
                textInputAction: TextInputAction.search,
                decoration: InputDecoration(
                  hintText: 'Buscar filmes, séries ou género',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Limpar pesquisa',
                          onPressed: () {
                            _searchController.clear();
                            context.read<CatalogoProvider>().definirBusca('');
                            setState(() {});
                          },
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
                onChanged: (value) {
                  context.read<CatalogoProvider>().definirBusca(value);
                  setState(() {});
                },
              ),
            ),
            Consumer<CatalogoProvider>(
              builder: (context, provider, _) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    children: [
                      _FiltroChip(
                        label: 'Todos',
                        value: FiltroCatalogo.todos,
                        selecionado: provider.filtroAtivo,
                      ),
                      _FiltroChip(
                        label: 'Filmes',
                        value: FiltroCatalogo.filmes,
                        selecionado: provider.filtroAtivo,
                      ),
                      _FiltroChip(
                        label: 'Séries',
                        value: FiltroCatalogo.series,
                        selecionado: provider.filtroAtivo,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Consumer<CatalogoProvider>(
                builder: (context, provider, _) {
                  final titulos = provider.titulosFiltrados;
                  final Widget conteudo;
                  if (provider.isLoading && provider.titulos.isEmpty) {
                    conteudo = ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(
                          height: 320,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.accent,
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (provider.erro != null &&
                      provider.titulos.isEmpty) {
                    conteudo = ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: _MensagemCatalogo(
                            icone: Icons.cloud_off_rounded,
                            titulo: 'Não foi possível carregar o catálogo',
                            descricao: provider.erro!,
                            acao: TextButton.icon(
                              onPressed: () =>
                                  provider.carregarDados().catchError((_) {}),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text('Tentar novamente'),
                            ),
                          ),
                        ),
                      ],
                    );
                  } else if (titulos.isEmpty) {
                    conteudo = ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        SizedBox(
                          height: 320,
                          child: _MensagemCatalogo(
                            icone: Icons.local_movies_outlined,
                            titulo: 'Nenhum título encontrado',
                            descricao:
                                'Experimente alterar a pesquisa ou o filtro.',
                          ),
                        ),
                      ],
                    );
                  } else {
                    conteudo = GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
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
                          onTap: () => _abrirDetalhes(titulo),
                          onFavoritePressed: () async {
                            try {
                              await provider.alternarFavorito(titulo.id);
                            } catch (_) {
                              // O erro fica disponível em provider.erro.
                            }
                          },
                        );
                      },
                    );
                  }

                  return RefreshIndicator(
                    color: AppTheme.accent,
                    onRefresh: () async {
                      try {
                        await provider.carregarDados();
                      } catch (_) {
                        // O erro já foi guardado pelo provider.
                      }
                    },
                    child: conteudo,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo título'),
      ),
    );
  }
}

class _FiltroChip extends StatelessWidget {
  const _FiltroChip({
    required this.label,
    required this.value,
    required this.selecionado,
  });

  final String label;
  final FiltroCatalogo value;
  final FiltroCatalogo selecionado;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: value == selecionado,
      onSelected: (_) => context.read<CatalogoProvider>().definirFiltro(value),
    );
  }
}

class _MensagemCatalogo extends StatelessWidget {
  const _MensagemCatalogo({
    required this.icone,
    required this.titulo,
    required this.descricao,
    this.acao,
  });

  final IconData icone;
  final String titulo;
  final String descricao;
  final Widget? acao;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 48, color: AppTheme.accent),
            const SizedBox(height: 14),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              descricao,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
            ),
            if (acao != null) ...[const SizedBox(height: 12), acao!],
          ],
        ),
      ),
    );
  }
}
