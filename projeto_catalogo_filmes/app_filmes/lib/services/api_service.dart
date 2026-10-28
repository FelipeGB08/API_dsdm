import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/catalogo_models.dart';

/// Exceção legível para falhas de rede ou respostas HTTP da API.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Cliente HTTP para a API Dart do catálogo.
class ApiService {
  ApiService({http.Client? client}) : _client = client ?? http.Client();

  /// Web, Desktop e simulador iOS: `http://localhost:8080`.
  /// Emulador Android: execute com
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8080`.
  /// Num iPhone físico, substitua pelo IP local do computador que executa a API.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  final http.Client _client;
  static const Duration _timeout = Duration(seconds: 15);
  static const Map<String, String> _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
    'Accept': 'application/json',
  };

  Future<List<TituloModel>> listarTitulos({String? tipo, String? busca}) async {
    final query = <String, String>{};
    if (tipo != null &&
        tipo.trim().isNotEmpty &&
        tipo.toLowerCase() != 'todos') {
      final valor = tipo.toLowerCase();
      query['tipo'] = valor.startsWith('fil') ? 'filme' : 'serie';
    }
    if (busca != null && busca.trim().isNotEmpty) {
      query['busca'] = busca.trim();
    }

    final data = await _request(
      'GET',
      '/titulos',
      queryParameters: query.isEmpty ? null : query,
    );
    if (data is! List) {
      throw const ApiException('A API retornou uma lista de títulos inválida.');
    }
    return data
        .whereType<Map>()
        .map((item) => TituloModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  Future<TituloModel> buscarDetalhesTitulo(int id) async {
    final data = await _request('GET', '/titulos/$id');
    return TituloModel.fromJson(_asJsonMap(data, 'detalhes do título'));
  }

  Future<TituloModel> criarTitulo(TituloModel titulo) async {
    final data = await _request('POST', '/titulos', body: _tituloBody(titulo));
    return TituloModel.fromJson(_asJsonMap(data, 'título criado'));
  }

  Future<TituloModel> editarTitulo(TituloModel titulo) async {
    final data = await _request(
      'PUT',
      '/titulos/${titulo.id}',
      body: _tituloBody(titulo),
    );
    if (data is Map) {
      final resposta = Map<String, dynamic>.from(data);
      if (resposta.containsKey('nome') || resposta.containsKey('titulo')) {
        return TituloModel.fromJson(resposta);
      }
    }
    return buscarDetalhesTitulo(titulo.id);
  }

  Future<void> excluirTitulo(int id) async {
    await _request('DELETE', '/titulos/$id');
  }

  Future<bool> alternarFavorito(int id) async {
    final data = await _request('PATCH', '/titulos/$id/favorito');
    final json = _asJsonMap(data, 'estado de favorito');
    final value = json['is_favorito'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    throw const ApiException('A API retornou o estado de favorito inválido.');
  }

  Future<AvaliacaoModel> criarAvaliacao({
    required int tituloId,
    required int nota,
    required String comentario,
  }) async {
    final data = await _request(
      'POST',
      '/titulos/$tituloId/avaliacoes',
      body: {'nota': nota, 'comentario': comentario},
    );
    return AvaliacaoModel.fromJson(_asJsonMap(data, 'avaliação criada'));
  }

  Future<void> excluirAvaliacao(int id) async {
    await _request('DELETE', '/avaliacoes/$id');
  }

  Future<List<ListaPersonalizadaModel>> listarListas() async {
    final data = await _request('GET', '/listas');
    if (data is! List) {
      throw const ApiException('A API retornou uma lista de listas inválida.');
    }
    return data
        .whereType<Map>()
        .map(
          (item) =>
              ListaPersonalizadaModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList(growable: false);
  }

  Future<ListaPersonalizadaModel> criarLista({
    required String nome,
    String descricao = '',
  }) async {
    final data = await _request(
      'POST',
      '/listas',
      body: {'nome': nome, 'descricao': descricao},
    );
    return ListaPersonalizadaModel.fromJson(_asJsonMap(data, 'lista criada'));
  }

  Future<void> excluirLista(int id) async {
    await _request('DELETE', '/listas/$id');
  }

  Future<void> adicionarTituloALista({
    required int listaId,
    required int tituloId,
  }) async {
    await _request(
      'POST',
      '/listas/$listaId/titulos',
      body: {'titulo_id': tituloId},
    );
  }

  Future<void> removerTituloDaLista({
    required int listaId,
    required int tituloId,
  }) async {
    await _request('DELETE', '/listas/$listaId/titulos/$tituloId');
  }

  Map<String, dynamic> _tituloBody(TituloModel titulo) => {
    'nome': titulo.titulo,
    'sinopse': titulo.sinopse,
    'ano_lancamento': titulo.anoLancamento,
    'genero': titulo.genero,
    'tipo': titulo.tipo,
    'url_poster': titulo.urlPoster,
    'is_favorito': titulo.isFavorito,
  };

  Map<String, dynamic> _asJsonMap(Object? value, String description) {
    if (value is Map) return Map<String, dynamic>.from(value);
    throw ApiException('A API retornou $description em formato inválido.');
  }

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, String>? queryParameters,
    Object? body,
  }) async {
    final uri = Uri.parse(
      '$baseUrl$path',
    ).replace(queryParameters: queryParameters);
    final encodedBody = body == null ? null : jsonEncode(body);

    try {
      late final http.Response response;
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: _jsonHeaders)
              .timeout(_timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: _jsonHeaders, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: _jsonHeaders, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: _jsonHeaders, body: encodedBody)
              .timeout(_timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: _jsonHeaders)
              .timeout(_timeout);
          break;
        default:
          throw ApiException('Método HTTP não suportado: $method.');
      }

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw ApiException(
          _messageFromResponse(response),
          statusCode: response.statusCode,
        );
      }
      if (response.body.trim().isEmpty) return null;
      try {
        return jsonDecode(response.body);
      } on FormatException {
        throw ApiException(
          'A API respondeu com JSON inválido (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } on ApiException {
      rethrow;
    } on http.ClientException catch (error) {
      throw ApiException(
        'Não foi possível comunicar com a API: ${error.message}',
      );
    } on TimeoutException {
      throw const ApiException(
        'A API demorou demasiado tempo para responder. Tente novamente.',
      );
    } catch (error) {
      throw ApiException('Falha de rede ao comunicar com a API: $error');
    }
  }

  String _messageFromResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        final message = decoded['erro'] ?? decoded['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    } on FormatException {
      // Usa a mensagem HTTP abaixo se a API não devolver JSON.
    }
    return 'A API respondeu com HTTP ${response.statusCode}.';
  }

  void close() => _client.close();
}
