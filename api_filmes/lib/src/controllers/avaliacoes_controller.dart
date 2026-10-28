import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:sqlite3/sqlite3.dart';

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
