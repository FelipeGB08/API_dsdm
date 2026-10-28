import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/catalogo_models.dart';
import '../providers/catalogo_provider.dart';
import '../theme/app_theme.dart';

class FormularioTituloScreen extends StatefulWidget {
  const FormularioTituloScreen({this.titulo, super.key});

  final TituloModel? titulo;

  @override
  State<FormularioTituloScreen> createState() => _FormularioTituloScreenState();
}

class _FormularioTituloScreenState extends State<FormularioTituloScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tituloController;
  late final TextEditingController _sinopseController;
  late final TextEditingController _anoController;
  late final TextEditingController _generoController;
  late final TextEditingController _posterController;
  String? _tipo;
  bool _isSaving = false;

  bool get _isEditing => widget.titulo != null;

  @override
  void initState() {
    super.initState();
    final titulo = widget.titulo;
    _tituloController = TextEditingController(text: titulo?.titulo ?? '');
    _sinopseController = TextEditingController(text: titulo?.sinopse ?? '');
    _anoController = TextEditingController(
      text: titulo == null || titulo.anoLancamento == 0
          ? ''
          : '${titulo.anoLancamento}',
    );
    _generoController = TextEditingController(text: titulo?.genero ?? '');
    _posterController = TextEditingController(text: titulo?.urlPoster ?? '');
    final tipo = titulo?.tipo.toLowerCase();
    _tipo = tipo == 'serie' || tipo == 'série' ? 'serie' : 'filme';
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _sinopseController.dispose();
    _anoController.dispose();
    _generoController.dispose();
    _posterController.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final model = TituloModel(
      id: widget.titulo?.id ?? 0,
      titulo: _tituloController.text.trim(),
      sinopse: _sinopseController.text.trim(),
      anoLancamento: int.parse(_anoController.text.trim()),
      genero: _generoController.text.trim(),
      tipo: _tipo!,
      urlPoster: _posterController.text.trim().isEmpty
          ? null
          : _posterController.text.trim(),
      isFavorito: widget.titulo?.isFavorito ?? false,
      mediaAvaliacoes: widget.titulo?.mediaAvaliacoes ?? 0,
      totalAvaliacoes: widget.titulo?.totalAvaliacoes ?? 0,
      avaliacoes: widget.titulo?.avaliacoes ?? const <AvaliacaoModel>[],
    );

    try {
      final provider = context.read<CatalogoProvider>();
      if (_isEditing) {
        await provider.editarTitulo(model);
      } else {
        await provider.criarTitulo(model);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isEditing
                ? 'Título atualizado com sucesso.'
                : 'Título cadastrado com sucesso.',
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível salvar: $error')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Editar título' : 'Novo título')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  TextFormField(
                    controller: _tituloController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Título',
                      hintText: 'Ex.: Interestelar',
                      prefixIcon: Icon(Icons.movie_creation_outlined),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Informe o título.'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _sinopseController,
                    minLines: 3,
                    maxLines: 6,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Sinopse',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _anoController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Ano de lançamento',
                      prefixIcon: Icon(Icons.calendar_today_outlined),
                    ),
                    validator: (value) {
                      final ano = int.tryParse(value?.trim() ?? '');
                      if (ano == null || ano < 1888 || ano > 2200) {
                        return 'Informe um ano válido entre 1888 e 2200.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _generoController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Género',
                      hintText: 'Ex.: Drama, ficção científica',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _tipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      prefixIcon: Icon(Icons.video_library_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'filme', child: Text('Filme')),
                      DropdownMenuItem(value: 'serie', child: Text('Série')),
                    ],
                    onChanged: (value) => setState(() => _tipo = value),
                    validator: (value) =>
                        value == null ? 'Selecione se é filme ou série.' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _posterController,
                    keyboardType: TextInputType.url,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'URL do póster',
                      hintText: 'https://exemplo.com/poster.jpg',
                      prefixIcon: Icon(Icons.image_outlined),
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) return null;
                      final uri = Uri.tryParse(text);
                      if (uri == null ||
                          !uri.hasScheme ||
                          (uri.scheme != 'http' && uri.scheme != 'https')) {
                        return 'Informe uma URL HTTP ou HTTPS válida.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _PosterPreview(url: _posterController.text.trim()),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _salvar,
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _isEditing ? 'Guardar alterações' : 'Cadastrar título',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PosterPreview extends StatelessWidget {
  const _PosterPreview({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (url.isEmpty || uri == null || !uri.hasScheme) {
      return Container(
        height: 190,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text(
            'A pré-visualização do póster aparece aqui',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 240,
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            );
          },
          errorBuilder: (context, error, stackTrace) => Container(
            color: AppTheme.surface,
            alignment: Alignment.center,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image_outlined, size: 38),
                SizedBox(height: 8),
                Text('Não foi possível carregar o póster'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
