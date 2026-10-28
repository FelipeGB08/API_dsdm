/// Converte valores decodificados de JSON para os tipos usados pelos modelos.
int _intFromJson(Object? value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

double _doubleFromJson(Object? value, {double fallback = 0}) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

bool _boolFromJson(Object? value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.toLowerCase()) {
      case 'true':
      case '1':
      case 'sim':
        return true;
      case 'false':
      case '0':
      case 'não':
      case 'nao':
        return false;
    }
  }
  return fallback;
}

DateTime? _dateTimeFromJson(Object? value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}

List<Map<String, dynamic>> _mapListFromJson(Object? value) {
  if (value is! List) return <Map<String, dynamic>>[];
  return value
      .whereType<Map>()
      .map((item) => Map<String, dynamic>.from(item))
      .toList();
}

/// Avaliação registrada para um filme ou uma série.
class AvaliacaoModel {
  const AvaliacaoModel({
    required this.id,
    required this.tituloId,
    required this.nota,
    this.comentario = '',
    this.dataCriacao,
  });

  final int id;
  final int tituloId;
  final double nota;
  final String comentario;
  final DateTime? dataCriacao;

  factory AvaliacaoModel.fromJson(Map<String, dynamic> json) {
    return AvaliacaoModel(
      id: _intFromJson(json['id']),
      tituloId: _intFromJson(json['titulo_id'] ?? json['tituloId']),
      nota: _doubleFromJson(json['nota']),
      comentario: (json['comentario'] as String?) ?? '',
      dataCriacao: _dateTimeFromJson(
        json['criado_em'] ?? json['data_criacao'] ?? json['dataCriacao'],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo_id': tituloId,
      'nota': nota,
      'comentario': comentario,
      'criado_em': dataCriacao?.toIso8601String(),
    };
  }
}

/// Filme ou série retornado pela API do catálogo.
class TituloModel {
  const TituloModel({
    required this.id,
    required this.titulo,
    required this.sinopse,
    required this.anoLancamento,
    required this.genero,
    required this.tipo,
    this.urlPoster,
    this.isFavorito = false,
    this.mediaAvaliacoes = 0,
    this.totalAvaliacoes = 0,
    this.avaliacoes = const <AvaliacaoModel>[],
  });

  final int id;
  final String titulo;
  final String sinopse;
  final int anoLancamento;
  final String genero;
  final String tipo;
  final String? urlPoster;
  final bool isFavorito;
  final double mediaAvaliacoes;
  final int totalAvaliacoes;
  final List<AvaliacaoModel> avaliacoes;

  factory TituloModel.fromJson(Map<String, dynamic> json) {
    final avaliacoesJson = _mapListFromJson(json['avaliacoes']);

    return TituloModel(
      id: _intFromJson(json['id']),
      titulo: (json['titulo'] ?? json['nome'] ?? json['title'] ?? '') as String,
      sinopse: (json['sinopse'] as String?) ?? '',
      anoLancamento: _intFromJson(
        json['ano_lancamento'] ?? json['anoLancamento'],
      ),
      genero: (json['genero'] as String?) ?? '',
      tipo: (json['tipo'] as String?) ?? '',
      urlPoster: (json['url_poster'] ?? json['urlPoster']) as String?,
      isFavorito: _boolFromJson(
        json['is_favorito'] ?? json['favorito'] ?? json['isFavorito'],
      ),
      mediaAvaliacoes: _doubleFromJson(
        json['media_avaliacoes'] ?? json['mediaAvaliacoes'],
      ),
      totalAvaliacoes: _intFromJson(
        json['quantidade_avaliacoes'] ??
            json['total_avaliacoes'] ??
            json['totalAvaliacoes'],
      ),
      avaliacoes: avaliacoesJson
          .map(AvaliacaoModel.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': titulo,
      'sinopse': sinopse,
      'ano_lancamento': anoLancamento,
      'genero': genero,
      'tipo': tipo,
      'url_poster': urlPoster,
      'is_favorito': isFavorito,
      'media_avaliacoes': mediaAvaliacoes,
      'quantidade_avaliacoes': totalAvaliacoes,
      'avaliacoes': avaliacoes.map((avaliacao) => avaliacao.toJson()).toList(),
    };
  }
}

/// Lista personalizada com os títulos associados a ela.
class ListaPersonalizadaModel {
  const ListaPersonalizadaModel({
    required this.id,
    required this.nome,
    required this.descricao,
    this.titulos = const <TituloModel>[],
  });

  final int id;
  final String nome;
  final String descricao;
  final List<TituloModel> titulos;

  factory ListaPersonalizadaModel.fromJson(Map<String, dynamic> json) {
    final titulosJson = _mapListFromJson(json['titulos']);

    return ListaPersonalizadaModel(
      id: _intFromJson(json['id']),
      nome: (json['nome'] as String?) ?? '',
      descricao: (json['descricao'] as String?) ?? '',
      titulos: titulosJson.map(TituloModel.fromJson).toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'titulos': titulos.map((titulo) => titulo.toJson()).toList(),
    };
  }
}
