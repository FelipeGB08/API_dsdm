import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart';

/// Abre e prepara o banco SQLite do catálogo.
class DatabaseConfig {
  DatabaseConfig._(this.connection);

  final Database connection;

  /// Cria a pasta e o arquivo do banco, configura as tabelas e insere
  /// títulos de exemplo quando [seed] é verdadeiro e a tabela está vazia.
  static DatabaseConfig open({
    String databasePath = 'data/catalogo.db',
    bool seed = true,
  }) {
    final absolutePath = p.absolute(databasePath);
    Directory(p.dirname(absolutePath)).createSync(recursive: true);

    final db = sqlite3.open(absolutePath);
    db.execute('PRAGMA foreign_keys = ON;');
    _createTables(db);

    if (seed) {
      _seedIfEmpty(db);
    }

    return DatabaseConfig._(db);
  }

  static void _createTables(Database db) {
    db.execute('''
      CREATE TABLE IF NOT EXISTS titulos (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        tipo TEXT NOT NULL CHECK (tipo IN ('filme', 'serie')),
        sinopse TEXT NOT NULL DEFAULT '',
        ano_lancamento INTEGER NOT NULL CHECK (ano_lancamento > 0),
        genero TEXT NOT NULL DEFAULT '',
        favorito INTEGER NOT NULL DEFAULT 0 CHECK (favorito IN (0, 1)),
        criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS avaliacoes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo_id INTEGER NOT NULL,
        nota REAL NOT NULL CHECK (nota >= 0 AND nota <= 10),
        comentario TEXT NOT NULL DEFAULT '',
        criado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (titulo_id) REFERENCES titulos(id) ON DELETE CASCADE
      );

      CREATE TABLE IF NOT EXISTS listas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nome TEXT NOT NULL,
        descricao TEXT NOT NULL DEFAULT '',
        criada_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP
      );

      CREATE TABLE IF NOT EXISTS lista_titulos (
        lista_id INTEGER NOT NULL,
        titulo_id INTEGER NOT NULL,
        adicionado_em TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
        PRIMARY KEY (lista_id, titulo_id),
        FOREIGN KEY (lista_id) REFERENCES listas(id) ON DELETE CASCADE,
        FOREIGN KEY (titulo_id) REFERENCES titulos(id) ON DELETE CASCADE
      );

      CREATE INDEX IF NOT EXISTS idx_avaliacoes_titulo_id
        ON avaliacoes(titulo_id);
      CREATE INDEX IF NOT EXISTS idx_lista_titulos_titulo_id
        ON lista_titulos(titulo_id);
    ''');
  }

  static void _seedIfEmpty(Database db) {
    final count = db.select('SELECT COUNT(*) AS total FROM titulos').first['total'] as int;
    if (count > 0) return;

    final insert = db.prepare('''
      INSERT INTO titulos (nome, tipo, sinopse, ano_lancamento, genero)
      VALUES (?, ?, ?, ?, ?)
    ''');

    try {
      db.execute('BEGIN TRANSACTION');
      final exemplos = [
        ['O Poderoso Chefão', 'filme', 'A saga da família mafiosa Corleone.', 1972, 'Crime, drama'],
        ['Interestelar', 'filme', 'Uma equipe viaja pelo espaço em busca de um novo lar para a humanidade.', 2014, 'Ficção científica, drama'],
        ['Breaking Bad', 'serie', 'Um professor de química passa a produzir metanfetamina.', 2008, 'Drama, crime'],
        ['Stranger Things', 'serie', 'Jovens enfrentam acontecimentos sobrenaturais em uma pequena cidade.', 2016, 'Ficção científica, drama'],
      ];
      for (final item in exemplos) {
        insert.execute(item);
      }
      db.execute('COMMIT');
    } catch (_) {
      db.execute('ROLLBACK');
      rethrow;
    } finally {
      insert.dispose();
    }
  }

  void close() => connection.dispose();
}
