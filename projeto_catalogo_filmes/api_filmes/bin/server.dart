import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_cors_headers/shelf_cors_headers.dart';
import 'package:shelf_router/shelf_router.dart';

import 'package:api_filmes/controllers/listas_avaliacoes_controller.dart';
import 'package:api_filmes/controllers/titulos_controller.dart';
import 'package:api_filmes/database/app_database.dart';

Future<void> main() async {
  final database = AppDatabase.open();
  final router = Router();

  TitulosController(database.connection).registerRoutes(router);
  AvaliacoesController(database.connection).registerRoutes(router);
  ListasController(database.connection).registerRoutes(router);

  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(corsHeaders())
      .addHandler(router);

  final server = await shelf_io.serve(handler, 'localhost', 8080);
  print('API rodando em http://${server.address.host}:${server.port}');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    database.close();
  });
}
