import 'package:flutter/material.dart';

import '../models/catalogo_models.dart';
import '../theme/app_theme.dart';

/// Cartão reutilizável para representar um filme ou uma série no catálogo.
class TituloCard extends StatelessWidget {
  const TituloCard({
    required this.titulo,
    required this.onTap,
    required this.onFavoritePressed,
    super.key,
  });

  final TituloModel titulo;
  final VoidCallback onTap;
  final VoidCallback onFavoritePressed;

  @override
  Widget build(BuildContext context) {
    final isSerie =
        titulo.tipo.toLowerCase() == 'serie' ||
        titulo.tipo.toLowerCase() == 'série';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _Poster(url: titulo.urlPoster),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.background.withValues(alpha: 0.86),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSerie ? 'Série' : 'Filme',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Material(
                      color: AppTheme.background.withValues(alpha: 0.78),
                      shape: const CircleBorder(),
                      child: IconButton(
                        tooltip: titulo.isFavorito
                            ? 'Remover dos favoritos'
                            : 'Adicionar aos favoritos',
                        onPressed: onFavoritePressed,
                        icon: Icon(
                          titulo.isFavorito
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: titulo.isFavorito
                              ? AppTheme.accentSecondary
                              : AppTheme.textPrimary,
                          size: 20,
                        ),
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo.titulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: AppTheme.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        titulo.totalAvaliacoes == 0
                            ? 'Sem avaliações'
                            : titulo.mediaAvaliacoes.toStringAsFixed(1),
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        '${titulo.anoLancamento}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final value = url?.trim() ?? '';
    final uri = Uri.tryParse(value);
    if (value.isEmpty || uri == null || !uri.hasScheme) {
      return const _PosterFallback();
    }

    return Image.network(
      value,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        final total = progress.expectedTotalBytes;
        return Container(
          color: AppTheme.surface,
          alignment: Alignment.center,
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppTheme.accent,
              value: total == null
                  ? null
                  : progress.cumulativeBytesLoaded / total,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) => const _PosterFallback(),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppTheme.surface,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_movies_outlined,
            color: AppTheme.textSecondary.withValues(alpha: 0.8),
            size: 42,
          ),
          const SizedBox(height: 8),
          Text(
            'Póster indisponível',
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }
}
