import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/catalogo_models.dart';
import '../providers/catalogo_provider.dart';
import '../theme/app_theme.dart';
import 'formulario_titulo_screen.dart';

class DetalhesTituloScreen extends StatefulWidget {
  const DetalhesTituloScreen({required this.titulo, super.key});

  final TituloModel titulo;

  @override
  State<DetalhesTituloScreen> createState() => _DetalhesTituloScreenState();
}

class _DetalhesTituloScreenState extends State<DetalhesTituloScreen> {
  late TituloModel _titulo;
  bool _carregandoDetalhes = true;

  @override
  void initState() {
    super.initState();
    _titulo = widget.titulo;
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarDetalhes());
  }

  Future<void> _carregarDetalhes() async {
    if (!mounted) return;
    setState(() => _carregandoDetalhes = true);
    try {
      final atualizado = await context
          .read<CatalogoProvider>()
          .carregarDetalhesTitulo(widget.titulo.id);
      if (mounted) setState(() => _titulo = atualizado);
    } catch (error) {
      if (mounted) {
        _mostrarMensagem('Não foi possível atualizar os detalhes: $error');
      }
    } finally {
      if (mounted) setState(() => _carregandoDetalhes = false);
    }
  }

  void _mostrarMensagem(String mensagem) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  Future<void> _alternarFavorito() async {
    final provider = context.read<CatalogoProvider>();
    try {
      await provider.alternarFavorito(_titulo.id);
      final titulos = provider.titulos;
      final index = titulos.indexWhere((item) => item.id == _titulo.id);
      if (index >= 0 && mounted) setState(() => _titulo = titulos[index]);
    } catch (error) {
      if (mounted) {
        _mostrarMensagem('Não foi possível atualizar o favorito: $error');
      }
    }
  }

  Future<void> _editar() async {
    final salvo = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FormularioTituloScreen(titulo: _titulo),
      ),
    );
    if (salvo == true && mounted) await _carregarDetalhes();
  }

  Future<void> _excluirTitulo() async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir título?'),
        content: Text(
          '“${_titulo.titulo}” e as avaliações associadas serão excluídos.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    try {
      await context.read<CatalogoProvider>().excluirTitulo(_titulo.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        _mostrarMensagem('Não foi possível excluir o título: $error');
      }
    }
  }

  Future<void> _avaliar() async {
    final controller = TextEditingController();
    var notaSelecionada = 5;
    final resultado = await showModalBottomSheet<Map<String, Object?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Avaliar título',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    final value = index + 1;
                    return IconButton(
                      tooltip: '$value estrela${value == 1 ? '' : 's'}',
                      onPressed: () =>
                          setModalState(() => notaSelecionada = value),
                      icon: Icon(
                        value <= notaSelecionada
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        color: AppTheme.accent,
                        size: 34,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  minLines: 2,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Comentário',
                    hintText: 'O que achou deste título?',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, {
                    'nota': notaSelecionada,
                    'comentario': controller.text.trim(),
                  }),
                  child: const Text('Enviar avaliação'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    controller.dispose();
    if (resultado == null || !mounted) return;

    try {
      await context.read<CatalogoProvider>().avaliarTitulo(
        tituloId: _titulo.id,
        nota: resultado['nota']! as int,
        comentario: resultado['comentario']! as String,
      );
      await _carregarDetalhes();
      if (mounted) _mostrarMensagem('Avaliação registada com sucesso.');
    } catch (error) {
      if (mounted)
        _mostrarMensagem('Não foi possível registar a avaliação: $error');
    }
  }

  Future<void> _excluirAvaliacao(AvaliacaoModel avaliacao) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir avaliação?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmado != true || !mounted) return;

    try {
      await context.read<CatalogoProvider>().excluirAvaliacao(
        tituloId: _titulo.id,
        avaliacaoId: avaliacao.id,
      );
      await _carregarDetalhes();
      if (mounted) _mostrarMensagem('Avaliação excluída.');
    } catch (error) {
      if (mounted)
        _mostrarMensagem('Não foi possível excluir a avaliação: $error');
    }
  }

  Future<void> _adicionarALista() async {
    final provider = context.read<CatalogoProvider>();
    try {
      await provider.carregarListas();
    } catch (error) {
      if (mounted)
        _mostrarMensagem('Não foi possível carregar as listas: $error');
      return;
    }
    if (!mounted) return;

    final listas = provider.listasPersonalizadas;
    final escolha = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
              child: Text(
                'Adicionar a uma lista',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (listas.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Ainda não criou nenhuma lista personalizada.'),
              ),
            for (final lista in listas)
              ListTile(
                leading: const Icon(Icons.playlist_add_check_rounded),
                title: Text(lista.nome),
                subtitle: Text('${lista.titulos.length} título(s)'),
                onTap: () => Navigator.pop(context, lista.id),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.add_rounded, color: AppTheme.accent),
              title: const Text('Criar nova lista'),
              onTap: () => Navigator.pop(context, -1),
            ),
          ],
        ),
      ),
    );
    if (escolha == null || !mounted) return;

    var listaId = escolha;
    if (escolha == -1) {
      final dados = await _pedirDadosLista();
      if (dados == null || !mounted) return;
      try {
        final lista = await provider.criarLista(
          nome: dados.$1,
          descricao: dados.$2,
        );
        listaId = lista.id;
      } catch (error) {
        if (mounted) _mostrarMensagem('Não foi possível criar a lista: $error');
        return;
      }
    }

    try {
      await provider.adicionarTituloALista(
        listaId: listaId,
        tituloId: _titulo.id,
      );
      if (mounted) _mostrarMensagem('Título adicionado à lista.');
    } catch (error) {
      if (mounted)
        _mostrarMensagem('Não foi possível adicionar à lista: $error');
    }
  }

  Future<(String, String)?> _pedirDadosLista() async {
    final nomeController = TextEditingController();
    final descricaoController = TextEditingController();
    final resultado = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova lista personalizada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomeController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descricaoController,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final nome = nomeController.text.trim();
              if (nome.isEmpty) return;
              Navigator.pop(context, (nome, descricaoController.text.trim()));
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
    nomeController.dispose();
    descricaoController.dispose();
    return resultado;
  }

  @override
  Widget build(BuildContext context) {
    final isSerie =
        _titulo.tipo.toLowerCase() == 'serie' ||
        _titulo.tipo.toLowerCase() == 'série';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes'),
        actions: [
          IconButton(
            tooltip: _titulo.isFavorito
                ? 'Remover dos favoritos'
                : 'Adicionar aos favoritos',
            onPressed: _alternarFavorito,
            icon: Icon(
              _titulo.isFavorito
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _titulo.isFavorito ? AppTheme.accentSecondary : null,
            ),
          ),
          IconButton(
            tooltip: 'Editar título',
            onPressed: _editar,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Excluir título',
            onPressed: _excluirTitulo,
            icon: const Icon(Icons.delete_outline_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.accent,
        onRefresh: _carregarDetalhes,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          children: [
            if (_carregandoDetalhes) ...[
              const LinearProgressIndicator(color: AppTheme.accent),
              const SizedBox(height: 12),
            ],
            _PosterDestaque(url: _titulo.urlPoster),
            const SizedBox(height: 20),
            Text(
              _titulo.titulo,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(label: '${_titulo.anoLancamento}'),
                _InfoChip(label: isSerie ? 'Série' : 'Filme'),
                if (_titulo.genero.trim().isNotEmpty)
                  _InfoChip(label: _titulo.genero),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                ...List.generate(5, (index) {
                  final isFilled = index < _titulo.mediaAvaliacoes.round();
                  return Icon(
                    isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
                    color: AppTheme.accent,
                    size: 22,
                  );
                }),
                const SizedBox(width: 8),
                Text(
                  _titulo.totalAvaliacoes == 0
                      ? 'Sem avaliações'
                      : '${_titulo.mediaAvaliacoes.toStringAsFixed(1)} · ${_titulo.totalAvaliacoes} avaliação(ões)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Sinopse', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              _titulo.sinopse.isEmpty
                  ? 'Ainda não há sinopse para este título.'
                  : _titulo.sinopse,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _adicionarALista,
              icon: const Icon(Icons.playlist_add_rounded),
              label: const Text('Adicionar a uma Lista Personalizada'),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Avaliações',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                TextButton.icon(
                  onPressed: _avaliar,
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Avaliar Título'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_titulo.avaliacoes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'Este título ainda não tem comentários. Seja a primeira pessoa a avaliar.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
              )
            else
              for (final avaliacao in _titulo.avaliacoes)
                _AvaliacaoTile(
                  avaliacao: avaliacao,
                  onDelete: () => _excluirAvaliacao(avaliacao),
                ),
          ],
        ),
      ),
    );
  }
}

class _PosterDestaque extends StatelessWidget {
  const _PosterDestaque({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final posterUrl = url?.trim() ?? '';
    final uri = Uri.tryParse(posterUrl);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 340,
        color: AppTheme.surface,
        child: posterUrl.isNotEmpty && uri != null && uri.hasScheme
            ? Image.network(
                posterUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.accent,
                        ),
                      ),
                errorBuilder: (context, error, stackTrace) =>
                    const _PosterIcon(),
              )
            : const _PosterIcon(),
      ),
    );
  }
}

class _PosterIcon extends StatelessWidget {
  const _PosterIcon();

  @override
  Widget build(BuildContext context) => const Center(
    child: Icon(
      Icons.local_movies_outlined,
      size: 68,
      color: AppTheme.textSecondary,
    ),
  );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Chip(label: Text(label));
}

class _AvaliacaoTile extends StatelessWidget {
  const _AvaliacaoTile({required this.avaliacao, required this.onDelete});

  final AvaliacaoModel avaliacao;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final data = avaliacao.dataCriacao;
    final dataFormatada = data == null
        ? ''
        : '${data.day.toString().padLeft(2, '0')}/${data.month.toString().padLeft(2, '0')}/${data.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 6, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.star_rounded,
                  color: AppTheme.accent,
                  size: 19,
                ),
                const SizedBox(width: 4),
                Text(avaliacao.nota.toStringAsFixed(0)),
                const Spacer(),
                if (dataFormatada.isNotEmpty)
                  Text(
                    dataFormatada,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                IconButton(
                  tooltip: 'Excluir avaliação',
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                ),
              ],
            ),
            if (avaliacao.comentario.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 24, right: 8),
                child: Text(avaliacao.comentario),
              ),
          ],
        ),
      ),
    );
  }
}
