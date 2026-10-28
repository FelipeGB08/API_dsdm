import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

/// Endpoints REST para cadastro e consulta de filmes e séries.
class TitulosController {
  TitulosController(this._db);

  final Database _db;

  Router get router {
    final router = Router();
    registerRoutes(router);
    return router;
  }

  void registerRoutes(Router router) {
    router.get('/titulos', _listar);
    router.get('/titulos/<id>', _buscarPorId);
    router.post('/titulos', _criar);
    router.put('/titulos/<id>', _editar);
    router.delete('/titulos/<id>', _excluir);
    router.patch('/titulos/<id>/favorito', _alternarFavorito);
  }

  static const _jsonHeaders = {
    'Content-Type': 'application/json; charset=utf-8',
  };

  Response _json(Object? body, {int statusCode = 200}) =>
      Response(statusCode, body: jsonEncode(body), headers: _jsonHeaders);

  Response _erro(String mensagem, {int statusCode = 400}) =>
      _json({'erro': mensagem}, statusCode: statusCode);

  Response _listar(Request request) {
    final query = request.url.queryParameters;
    final tipo = query['tipo']?.trim().toLowerCase();
    final busca = query['busca']?.trim();

    final conditions = <String>[];
    final values = <Object?>[];

    if (tipo != null && tipo.isNotEmpty) {
      final tipoNormalizado = _normalizarTipo(tipo);
      if (tipoNormalizado == null) {
        return _erro('O parâmetro tipo deve ser "Filme" ou "Série".');
      }
      conditions.add('LOWER(t.tipo) = ?');
      values.add(tipoNormalizado);
    }

    if (busca != null && busca.isNotEmpty) {
      conditions.add('LOWER(t.nome) LIKE ?');
      values.add('%${busca.toLowerCase()}%');
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final rows = _db.select('''
      SELECT t.id, t.nome, t.tipo, t.sinopse, t.ano_lancamento, t.genero,
             t.favorito AS is_favorito, t.criado_em,
             COALESCE(AVG(a.nota), 0) AS media_avaliacoes,
             COUNT(a.id) AS quantidade_avaliacoes
      FROM titulos t
      LEFT JOIN avaliacoes a ON a.titulo_id = t.id
      $where
      GROUP BY t.id
      ORDER BY t.nome COLLATE NOCASE
    ''', values);

    return _json(rows.map((row) => row.toColumnMap()).toList());
  }

  Response _buscarPorId(Request request, String id) {
    final tituloId = int.tryParse(id);
    if (tituloId == null || tituloId <= 0) return _erro('ID inválido.');

    final rows = _db.select(
      '''
      SELECT t.id, t.nome, t.tipo, t.sinopse, t.ano_lancamento, t.genero,
             t.favorito AS is_favorito, t.criado_em,
             COALESCE(AVG(a.nota), 0) AS media_avaliacoes,
             COUNT(a.id) AS quantidade_avaliacoes
      FROM titulos t
      LEFT JOIN avaliacoes a ON a.titulo_id = t.id
      WHERE t.id = ?
      GROUP BY t.id
    ''',
      [tituloId],
    );

    if (rows.isEmpty) return _erro('Título não encontrado.', statusCode: 404);

    final avaliacoes = _db.select(
      '''
      SELECT id, titulo_id, nota, comentario, criado_em
      FROM avaliacoes
      WHERE titulo_id = ?
      ORDER BY criado_em DESC, id DESC
    ''',
      [tituloId],
    );

    return _json({
      ...rows.first.toColumnMap(),
      'avaliacoes': avaliacoes.map((row) => row.toColumnMap()).toList(),
    });
  }

  Future<Response> _criar(Request request) async {
    final body = await _lerJson(request);
    if (body == null) return _erro('Envie um objeto JSON válido.');

    final nome = body['nome'];
    final tipo = _normalizarTipo(body['tipo']?.toString().toLowerCase());
    final ano = body['ano_lancamento'];
    if (nome is! String ||
        nome.trim().isEmpty ||
        tipo == null ||
        ano is! int ||
        ano <= 0) {
      return _erro(
        'Informe nome, tipo (Filme ou Série) e ano_lancamento válido.',
      );
    }

    final sinopse = body['sinopse'] is String ? body['sinopse'] as String : '';
    final genero = body['genero'] is String ? body['genero'] as String : '';
    _db.execute(
      '''
      INSERT INTO titulos (nome, tipo, sinopse, ano_lancamento, genero)
      VALUES (?, ?, ?, ?, ?)
    ''',
      [nome.trim(), tipo, sinopse, ano, genero],
    );

    final id = _db.lastInsertRowId;
    return _json({
      'id': id,
      'nome': nome.trim(),
      'tipo': tipo,
      'sinopse': sinopse,
      'ano_lancamento': ano,
      'genero': genero,
      'is_favorito': 0,
    }, statusCode: 201);
  }

  Future<Response> _editar(Request request, String id) async {
    final tituloId = int.tryParse(id);
    if (tituloId == null || tituloId <= 0) return _erro('ID inválido.');
    if (_db.select('SELECT id FROM titulos WHERE id = ?', [tituloId]).isEmpty) {
      return _erro('Título não encontrado.', statusCode: 404);
    }

    final body = await _lerJson(request);
    if (body == null) return _erro('Envie um objeto JSON válido.');
    final nome = body['nome'];
    final tipo = _normalizarTipo(body['tipo']?.toString().toLowerCase());
    final ano = body['ano_lancamento'];
    if (nome is! String ||
        nome.trim().isEmpty ||
        tipo == null ||
        ano is! int ||
        ano <= 0) {
      return _erro(
        'Informe nome, tipo (Filme ou Série) e ano_lancamento válido.',
      );
    }
    final sinopse = body['sinopse'] is String ? body['sinopse'] as String : '';
    final genero = body['genero'] is String ? body['genero'] as String : '';
    final favorito = body['is_favorito'];
    if (favorito != null &&
        favorito is! bool &&
        favorito != 0 &&
        favorito != 1) {
      return _erro('is_favorito deve ser booleano, 0 ou 1.');
    }
    final favoritoInt = favorito == true || favorito == 1
        ? 1
        : favorito == false || favorito == 0
        ? 0
        : null;

    _db.execute(
      '''
      UPDATE titulos
      SET nome = ?, tipo = ?, sinopse = ?, ano_lancamento = ?, genero = ?
          ${favoritoInt == null ? '' : ', favorito = ?'}
      WHERE id = ?
    ''',
      [
        nome.trim(),
        tipo,
        sinopse,
        ano,
        genero,
        if (favoritoInt != null) favoritoInt,
        tituloId,
      ],
    );

    return _json({
      'mensagem': 'Título atualizado com sucesso.',
      'id': tituloId,
    });
  }

  Response _excluir(Request request, String id) {
    final tituloId = int.tryParse(id);
    if (tituloId == null || tituloId <= 0) return _erro('ID inválido.');
    final existing = _db.select('SELECT id FROM titulos WHERE id = ?', [
      tituloId,
    ]);
    if (existing.isEmpty)
      return _erro('Título não encontrado.', statusCode: 404);

    _db.execute('DELETE FROM titulos WHERE id = ?', [tituloId]);
    return _json({'mensagem': 'Título excluído com sucesso.'});
  }

  Response _alternarFavorito(Request request, String id) {
    final tituloId = int.tryParse(id);
    if (tituloId == null || tituloId <= 0) return _erro('ID inválido.');
    final existing = _db.select('SELECT favorito FROM titulos WHERE id = ?', [
      tituloId,
    ]);
    if (existing.isEmpty)
      return _erro('Título não encontrado.', statusCode: 404);

    final atual = existing.first['favorito'] as int;
    final novoStatus = atual == 1 ? 0 : 1;
    _db.execute('UPDATE titulos SET favorito = ? WHERE id = ?', [
      novoStatus,
      tituloId,
    ]);
    return _json({'id': tituloId, 'is_favorito': novoStatus});
  }

  Future<Map<String, dynamic>?> _lerJson(Request request) async {
    try {
      final decoded = jsonDecode(await request.readAsString());
      if (decoded is Map<String, dynamic>) return decoded;
      return null;
    } on FormatException {
      return null;
    }
  }

  String? _normalizarTipo(String? tipo) {
    switch (tipo?.toLowerCase()) {
      case 'filme':
        return 'filme';
      case 'série':
      case 'serie':
        return 'serie';
      default:
        return null;
    }
  }
}
