import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

/// Agrupa os endpoints de avaliações e listas personalizadas.
class ListasAvaliacoesController {
  ListasAvaliacoesController(this._db);

  final Database _db;

  void registerRoutes(Router router) {
    AvaliacoesController(_db).registerRoutes(router);
    ListasController(_db).registerRoutes(router);
  }
}

/// Endpoints para criar e remover avaliações de títulos.
class AvaliacoesController {
  AvaliacoesController(this._db);

  final Database _db;

  void registerRoutes(Router router) {
    router.post('/titulos/<id>/avaliacoes', _criar);
    router.delete('/avaliacoes/<id>', _excluir);
  }

  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  Response _json(Object? body, {int statusCode = 200}) =>
      Response(statusCode, body: jsonEncode(body), headers: _headers);

  Response _erro(String mensagem, {int statusCode = 400}) =>
      _json({'erro': mensagem}, statusCode: statusCode);

  Future<Response> _criar(Request request, String id) async {
    final tituloId = int.tryParse(id);
    if (tituloId == null || tituloId <= 0)
      return _erro('ID do título inválido.');
    if (_db.select('SELECT id FROM titulos WHERE id = ?', [tituloId]).isEmpty) {
      return _erro('Título não encontrado.', statusCode: 404);
    }

    final body = await _lerJson(request);
    if (body == null) return _erro('Envie um objeto JSON válido.');
    final nota = body['nota'];
    final comentario = body['comentario'];
    if (nota is! num || nota < 1 || nota > 5) {
      return _erro('A nota deve ser um número entre 1 e 5.');
    }
    if (comentario != null && comentario is! String) {
      return _erro('comentario deve ser um texto.');
    }

    final texto = (comentario as String?)?.trim() ?? '';
    _db.execute(
      '''
      INSERT INTO avaliacoes (titulo_id, nota, comentario)
      VALUES (?, ?, ?)
    ''',
      [tituloId, nota.toDouble(), texto],
    );

    return _json({
      'id': _db.lastInsertRowId,
      'titulo_id': tituloId,
      'nota': nota,
      'comentario': texto,
    }, statusCode: 201);
  }

  Response _excluir(Request request, String id) {
    final avaliacaoId = int.tryParse(id);
    if (avaliacaoId == null || avaliacaoId <= 0)
      return _erro('ID da avaliação inválido.');
    if (_db.select('SELECT id FROM avaliacoes WHERE id = ?', [
      avaliacaoId,
    ]).isEmpty) {
      return _erro('Avaliação não encontrada.', statusCode: 404);
    }

    _db.execute('DELETE FROM avaliacoes WHERE id = ?', [avaliacaoId]);
    return _json({'mensagem': 'Avaliação excluída com sucesso.'});
  }

  Future<Map<String, dynamic>?> _lerJson(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}

/// Endpoints para listas personalizadas e seus títulos associados.
class ListasController {
  ListasController(this._db);

  final Database _db;

  void registerRoutes(Router router) {
    router.get('/listas', _listar);
    router.post('/listas', _criar);
    router.post('/listas/<id>/titulos', _adicionarTitulo);
    router.delete('/listas/<id>/titulos/<tituloId>', _removerTitulo);
    router.delete('/listas/<id>', _excluir);
  }

  static const _headers = {'Content-Type': 'application/json; charset=utf-8'};

  Response _json(Object? body, {int statusCode = 200}) =>
      Response(statusCode, body: jsonEncode(body), headers: _headers);

  Response _erro(String mensagem, {int statusCode = 400}) =>
      _json({'erro': mensagem}, statusCode: statusCode);

  Response _listar(Request request) {
    final rows = _db.select('''
      SELECT l.id, l.nome, l.descricao, l.criada_em,
             t.id AS titulo_id, t.nome AS titulo_nome, t.tipo AS titulo_tipo,
             t.sinopse AS titulo_sinopse, t.ano_lancamento AS titulo_ano_lancamento,
             t.genero AS titulo_genero, t.url_poster AS titulo_url_poster,
             t.favorito AS titulo_is_favorito
      FROM listas l
      LEFT JOIN lista_titulos lt ON lt.lista_id = l.id
      LEFT JOIN titulos t ON t.id = lt.titulo_id
      ORDER BY l.id, t.nome COLLATE NOCASE
    ''');

    final listas = <int, Map<String, dynamic>>{};
    for (final row in rows) {
      final listaId = row['id'] as int;
      final lista = listas.putIfAbsent(
        listaId,
        () => {
          'id': listaId,
          'nome': row['nome'],
          'descricao': row['descricao'],
          'criada_em': row['criada_em'],
          'titulos': <Map<String, Object?>>[],
        },
      );

      final tituloId = row['titulo_id'] as int?;
      if (tituloId != null) {
        (lista['titulos'] as List<Map<String, Object?>>).add({
          'id': tituloId,
          'nome': row['titulo_nome'],
          'tipo': row['titulo_tipo'],
          'sinopse': row['titulo_sinopse'],
          'ano_lancamento': row['titulo_ano_lancamento'],
          'genero': row['titulo_genero'],
          'url_poster': row['titulo_url_poster'],
          'is_favorito': row['titulo_is_favorito'],
        });
      }
    }

    return _json(listas.values.toList());
  }

  Future<Response> _criar(Request request) async {
    final body = await _lerJson(request);
    if (body == null) return _erro('Envie um objeto JSON válido.');
    final nome = body['nome'];
    final descricao = body['descricao'];
    if (nome is! String || nome.trim().isEmpty) {
      return _erro('nome é obrigatório e deve ser um texto.');
    }
    if (descricao != null && descricao is! String) {
      return _erro('descricao deve ser um texto.');
    }

    final textoDescricao = (descricao as String?)?.trim() ?? '';
    _db.execute('INSERT INTO listas (nome, descricao) VALUES (?, ?)', [
      nome.trim(),
      textoDescricao,
    ]);
    return _json({
      'id': _db.lastInsertRowId,
      'nome': nome.trim(),
      'descricao': textoDescricao,
      'titulos': <Object>[],
    }, statusCode: 201);
  }

  Future<Response> _adicionarTitulo(Request request, String id) async {
    final listaId = int.tryParse(id);
    if (listaId == null || listaId <= 0) return _erro('ID da lista inválido.');
    if (_db.select('SELECT id FROM listas WHERE id = ?', [listaId]).isEmpty) {
      return _erro('Lista não encontrada.', statusCode: 404);
    }

    final body = await _lerJson(request);
    if (body == null) return _erro('Envie um objeto JSON válido.');
    final tituloId = body['titulo_id'];
    if (tituloId is! int || tituloId <= 0)
      return _erro('titulo_id deve ser um inteiro positivo.');
    if (_db.select('SELECT id FROM titulos WHERE id = ?', [tituloId]).isEmpty) {
      return _erro('Título não encontrado.', statusCode: 404);
    }
    if (_db.select(
      'SELECT 1 FROM lista_titulos WHERE lista_id = ? AND titulo_id = ?',
      [listaId, tituloId],
    ).isNotEmpty) {
      return _erro('Esse título já está na lista.', statusCode: 409);
    }

    _db.execute(
      'INSERT INTO lista_titulos (lista_id, titulo_id) VALUES (?, ?)',
      [listaId, tituloId],
    );
    return _json({
      'mensagem': 'Título adicionado à lista.',
      'lista_id': listaId,
      'titulo_id': tituloId,
    }, statusCode: 201);
  }

  Response _removerTitulo(Request request, String id, String tituloId) {
    final listaId = int.tryParse(id);
    final filmeId = int.tryParse(tituloId);
    if (listaId == null || listaId <= 0 || filmeId == null || filmeId <= 0) {
      return _erro('ID da lista ou do título inválido.');
    }
    final vinculo = _db.select(
      'SELECT 1 FROM lista_titulos WHERE lista_id = ? AND titulo_id = ?',
      [listaId, filmeId],
    );
    if (vinculo.isEmpty)
      return _erro('Título não encontrado nessa lista.', statusCode: 404);

    _db.execute(
      'DELETE FROM lista_titulos WHERE lista_id = ? AND titulo_id = ?',
      [listaId, filmeId],
    );
    return _json({'mensagem': 'Título removido da lista.'});
  }

  Response _excluir(Request request, String id) {
    final listaId = int.tryParse(id);
    if (listaId == null || listaId <= 0) return _erro('ID da lista inválido.');
    if (_db.select('SELECT id FROM listas WHERE id = ?', [listaId]).isEmpty) {
      return _erro('Lista não encontrada.', statusCode: 404);
    }

    _db.execute('DELETE FROM listas WHERE id = ?', [listaId]);
    return _json({'mensagem': 'Lista excluída com sucesso.'});
  }

  Future<Map<String, dynamic>?> _lerJson(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
