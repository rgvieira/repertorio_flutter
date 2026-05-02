import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:repertorio_flutter/widgets/file_list_item.dart';
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';

class MusicasRepertorioPage extends StatefulWidget {
  final String repertorioId;

  const MusicasRepertorioPage({super.key, required this.repertorioId});

  @override
  State<MusicasRepertorioPage> createState() => _MusicasRepertorioPageState();
}

class _MusicasRepertorioPageState extends State<MusicasRepertorioPage> {
  final BannerAdManager _bannerAdManager = BannerAdManager();
  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadBanner();
  }

  Future<void> _loadBanner() async {
    await _bannerAdManager.loadBanner();
    if (mounted) {
      setState(() => _adLoaded = true);
    }
  }

  @override
  void dispose() {
    _bannerAdManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('minha_biblioteca');
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box b, _) {
            final repertorio = b.get(widget.repertorioId);
            final nome = (repertorio is Map && repertorio['nome'] != null)
                ? repertorio['nome'].toString()
                : 'Repertório';
            return Text(
              nome,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: scheme.onPrimary,
              ),
            );
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          final repertorio = b.get(widget.repertorioId);
          if (repertorio == null || repertorio is! Map) {
            return Center(
              child: Text(
                'Repertório não encontrado',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            );
          }

          final List<dynamic> musicasIds = repertorio['musicas'] ?? [];

          if (musicasIds.isEmpty) {
            return Center(
              child: Text(
                'Nenhuma música neste repertório',
                style: TextStyle(
                  fontSize: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            );
          }

          final List<Map> musicas = [];
          for (final id in musicasIds) {
            final arquivo = b.get(id);
            if (arquivo is Map) {
              musicas.add(Map<String, dynamic>.from(arquivo));
            }
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.separated(
              itemCount: musicas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final musica = musicas[index];
                return FileListItem(
                  item: musica,
                  showFavorite: false,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _adLoaded
          ? _bannerAdManager.buildBannerWidget() // Usando o método correto
          : null,
    );
  }
}
