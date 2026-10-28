import 'package:flutter/foundation.dart';

import '../models/catalogo_models.dart';
import '../services/api_service.dart';

enum FiltroCatalogo { todos, filmes, series }

/// Mantém os dados do catálogo e notifica a interface após cada alteração.
class CatalogoProvider extends ChangeNotifier {
  CatalogoProvider({ApiService? apiService})
    : _apiService = apiService ?? ApiService();

  final ApiService _apiService;

  List<TituloModel> _titulos = <TituloModel>[];
  List<ListaPersonalizadaModel> _listas = <ListaPersonalizadaModel>[];
  FiltroCatalogo _filtroAtivo = FiltroCatalogo.todos;
  String _textoBusca = '';
  bool _isLoading = false;
  String? _erro;

  List<TituloModel> get titulos => List.unmodifiable(_titulos);
  List<ListaPersonalizadaModel> get listasPersonalizadas =>
      List.unmodifiable(_listas);
  List<TituloModel> get favoritos =>
      List.unmodifiable(_titulos.where((titulo) => titulo.isFavorito));
  FiltroCatalogo get filtroAtivo => _filtroAtivo;
  String get textoBusca => _textoBusca;
  bool get isLoading => _isLoading;
  String? get erro => _erro;

  List<TituloModel> get titulosFiltrados {
    final termo = _textoBusca.trim().toLowerCase();
    return List.unmodifiable(
      _titulos.where((titulo) {
        final tipo = titulo.tipo.toLowerCase();
        final correspondeTipo = switch (_filtroAtivo) {
          FiltroCatalogo.todos => true,
          FiltroCatalogo.filmes => tipo == 'filme',
          FiltroCatalogo.series => tipo == 'serie' || tipo == 'série',
        };
        final correspondeBusca =
            termo.isEmpty ||
            titulo.titulo.toLowerCase().contains(termo) ||
            titulo.genero.toLowerCase().contains(termo) ||
            titulo.sinopse.toLowerCase().contains(termo);
        return correspondeTipo && correspondeBusca;
      }),
    );
  }

  void definirFiltro(FiltroCatalogo filtro) {
    if (_filtroAtivo == filtro) return;
    _filtroAtivo = filtro;
    notifyListeners();
  }

  void definirBusca(String texto) {
    if (_textoBusca == texto) return;
    _textoBusca = texto;
    notifyListeners();
  }

  Future<void> carregarDados() => _executar(() async {
    final resultados = await Future.wait<Object>([
      _apiService.listarTitulos(),
      _apiService.listarListas(),
    ]);
    _titulos = resultados[0] as List<TituloModel>;
    _listas = resultados[1] as List<ListaPersonalizadaModel>;
  });

  Future<void> carregarCatalogo() => _executar(() async {
    _titulos = await _apiService.listarTitulos();
  });

  Future<void> carregarListas() => _executar(() async {
    _listas = await _apiService.listarListas();
  });

  Future<TituloModel> carregarDetalhesTitulo(int id) => _executar(() async {
    final titulo = await _apiService.buscarDetalhesTitulo(id);
    _upsertTitulo(titulo);
    return titulo;
  });

  Future<TituloModel> criarTitulo(TituloModel titulo) => _executar(() async {
    final criado = await _apiService.criarTitulo(titulo);
    _upsertTitulo(criado);
    return criado;
  });

  Future<TituloModel> editarTitulo(TituloModel titulo) => _executar(() async {
    await _apiService.editarTitulo(titulo);
    final atualizado = await _apiService.buscarDetalhesTitulo(titulo.id);
    _upsertTitulo(atualizado);
    _atualizarTituloNasListas(atualizado);
    return atualizado;
  });

  Future<void> excluirTitulo(int id) => _executar(() async {
    await _apiService.excluirTitulo(id);
    _titulos.removeWhere((titulo) => titulo.id == id);
    _listas = _listas
        .map(
          (lista) => ListaPersonalizadaModel(
            id: lista.id,
            nome: lista.nome,
            descricao: lista.descricao,
            titulos: lista.titulos
                .where((titulo) => titulo.id != id)
                .toList(growable: false),
          ),
        )
        .toList(growable: false);
  });

  Future<bool> alternarFavorito(int id) => _executar(() async {
    final index = _titulos.indexWhere((titulo) => titulo.id == id);
    final anterior = index < 0 ? null : _titulos[index];
    if (anterior != null) {
      _titulos[index] = _copiarTitulo(
        anterior,
        isFavorito: !anterior.isFavorito,
      );
      _atualizarTituloNasListas(_titulos[index]);
      notifyListeners();
    }

    try {
      final status = await _apiService.alternarFavorito(id);
      if (index >= 0 && index < _titulos.length && _titulos[index].id == id) {
        _titulos[index] = _copiarTitulo(_titulos[index], isFavorito: status);
        _atualizarTituloNasListas(_titulos[index]);
      }
      return status;
    } catch (_) {
      if (anterior != null) {
        _titulos[index] = anterior;
        _atualizarTituloNasListas(anterior);
        notifyListeners();
      }
      rethrow;
    }
  });

  Future<AvaliacaoModel> avaliarTitulo({
    required int tituloId,
    required int nota,
    required String comentario,
  }) => _executar(() async {
    final avaliacao = await _apiService.criarAvaliacao(
      tituloId: tituloId,
      nota: nota,
      comentario: comentario,
    );
    final atualizado = await _apiService.buscarDetalhesTitulo(tituloId);
    _upsertTitulo(atualizado);
    _atualizarTituloNasListas(atualizado);
    return avaliacao;
  });

  Future<void> excluirAvaliacao({
    required int tituloId,
    required int avaliacaoId,
  }) => _executar(() async {
    await _apiService.excluirAvaliacao(avaliacaoId);
    final atualizado = await _apiService.buscarDetalhesTitulo(tituloId);
    _upsertTitulo(atualizado);
    _atualizarTituloNasListas(atualizado);
  });

  Future<ListaPersonalizadaModel> criarLista({
    required String nome,
    String descricao = '',
  }) => _executar(() async {
    final lista = await _apiService.criarLista(
      nome: nome,
      descricao: descricao,
    );
    _upsertLista(lista);
    return lista;
  });

  Future<void> excluirLista(int id) => _executar(() async {
    await _apiService.excluirLista(id);
    _listas.removeWhere((lista) => lista.id == id);
  });

  Future<void> adicionarTituloALista({
    required int listaId,
    required int tituloId,
  }) => _executar(() async {
    await _apiService.adicionarTituloALista(
      listaId: listaId,
      tituloId: tituloId,
    );
    _listas = await _apiService.listarListas();
  });

  Future<void> removerTituloDaLista({
    required int listaId,
    required int tituloId,
  }) => _executar(() async {
    await _apiService.removerTituloDaLista(
      listaId: listaId,
      tituloId: tituloId,
    );
    _listas = await _apiService.listarListas();
  });

  void limparErro() {
    if (_erro == null) return;
    _erro = null;
    notifyListeners();
  }

  Future<T> _executar<T>(Future<T> Function() operacao) async {
    _isLoading = true;
    _erro = null;
    notifyListeners();
    try {
      return await operacao();
    } catch (error) {
      _erro = error.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _upsertTitulo(TituloModel titulo) {
    final index = _titulos.indexWhere((item) => item.id == titulo.id);
    if (index == -1) {
      _titulos = [..._titulos, titulo];
    } else {
      _titulos[index] = titulo;
    }
  }

  void _atualizarTituloNasListas(TituloModel titulo) {
    _listas = _listas
        .map((lista) {
          final index = lista.titulos.indexWhere(
            (item) => item.id == titulo.id,
          );
          if (index == -1) return lista;
          final titulos = [...lista.titulos];
          titulos[index] = titulo;
          return ListaPersonalizadaModel(
            id: lista.id,
            nome: lista.nome,
            descricao: lista.descricao,
            titulos: titulos,
          );
        })
        .toList(growable: false);
  }

  void _upsertLista(ListaPersonalizadaModel lista) {
    final index = _listas.indexWhere((item) => item.id == lista.id);
    if (index == -1) {
      _listas = [..._listas, lista];
    } else {
      _listas[index] = lista;
    }
  }

  TituloModel _copiarTitulo(TituloModel titulo, {required bool isFavorito}) {
    return TituloModel(
      id: titulo.id,
      titulo: titulo.titulo,
      sinopse: titulo.sinopse,
      anoLancamento: titulo.anoLancamento,
      genero: titulo.genero,
      tipo: titulo.tipo,
      urlPoster: titulo.urlPoster,
      isFavorito: isFavorito,
      mediaAvaliacoes: titulo.mediaAvaliacoes,
      totalAvaliacoes: titulo.totalAvaliacoes,
      avaliacoes: titulo.avaliacoes,
    );
  }

  @override
  void dispose() {
    _apiService.close();
    super.dispose();
  }
}
