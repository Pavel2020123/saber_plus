import 'package:flutter/material.dart';

import '../domain/ranking_badge_catalog.dart';

class RankingBadgeCatalogPage extends StatefulWidget {
  const RankingBadgeCatalogPage({super.key});

  @override
  State<RankingBadgeCatalogPage> createState() =>
      _RankingBadgeCatalogPageState();
}

class _RankingBadgeCatalogPageState extends State<RankingBadgeCatalogPage> {
  BadgeGame _game = BadgeGame.trivia;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Insignias de Sabi')),
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Catálogo de diseños',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Estas imágenes no son insignias obtenidas. La asignación por juego '
          'y la colección anual se habilitarán al conectar el ranking verificado.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final game in BadgeGame.values)
              ChoiceChip(
                label: Text(game.label),
                selected: _game == game,
                onSelected: (_) => setState(() => _game = game),
              ),
          ],
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = (constraints.maxWidth / 170).floor().clamp(1, 4);
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final art in RankingBadgeArt.forGame(_game))
                  SizedBox(
                    width: width,
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showDetail(context, art),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            children: [
                              _BadgeImage(art: art, size: 140),
                              const SizedBox(height: 8),
                              Text(art.rangeLabel),
                              const Text('Ver detalle'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        const Text(
          'Diseños disponibles: puestos 1–50. Los puestos 51–100 y los demás '
          'juegos están pendientes; no se sustituyen por medallas de otro rango.',
        ),
      ],
    ),
  );

  void _showDetail(BuildContext context, RankingBadgeArt art) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${art.game.label} · ${art.rangeLabel}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _BadgeImage(art: art, size: 220),
              const SizedBox(height: 12),
              const Text(
                'Vista previa, no obtenida. El puesto exacto y el año vendrán '
                'del servidor. Las distinciones anuales conservarán su año '
                'sin reemplazar las de temporadas anteriores.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _BadgeImage extends StatelessWidget {
  const _BadgeImage({required this.art, required this.size});
  final RankingBadgeArt art;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    art.assetPath,
    width: size,
    height: size,
    fit: BoxFit.contain,
    cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).round(),
    semanticLabel: '${art.game.label}, ${art.rangeLabel}, diseño de insignia',
    errorBuilder: (_, _, _) => SizedBox(
      width: size,
      height: size,
      child: const Center(child: Text('Imagen no disponible')),
    ),
  );
}
