import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';
import 'package:repertorio_flutter/widgets/file_list_item.dart';

class DetalhesPastaPage extends StatefulWidget {
  final String rootPath;
  final String folderName;
  final bool alwaysFlat;

  const DetalhesPastaPage({
    super.key,
    required this.rootPath,
    required this.folderName,
    this.alwaysFlat = false,
  });

  @override
  State<DetalhesPastaPage> createState() => _DetalhesPastaPageState();
}

class _DetalhesPastaPageState extends State<DetalhesPastaPage> {
  final Box _box = Hive.box('minha_biblioteca');
  final BannerAdManager _bannerAdManager = BannerAdManager();

  String _textoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !kIsWeb) {
        _bannerAdManager.loadBanner(context);
      }
    });
  }

  @override
  void dispose() {
    _bannerAdManager.dispose();
    _buscaController.dispose();
    super.dispose();
  }

  Future<void> _confirmarExclusaoSubpasta(
      String fullPath, String nome) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover subpasta?'),
        content: Text(
            'Isso apagará o índice da pasta "$nome" e de todos os seus arquivos no app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remover', style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final keys = _box.keys.where((k) {
      final item = _box.get(k);
      return k == fullPath ||
          (item is Map &&
              item['fullPath']?.toString().startsWith('$fullPath/') == true);
    }).toList();
    await _box.deleteAll(keys);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.folderName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar:
          kIsWeb ? null : _bannerAdManager.buildBannerWidget(),
      body: Column(
        children: [
          _buildBuscaGlobal(),
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final buscaLower = _textoBusca.trim().toLowerCase();
    final modoBusca = widget.alwaysFlat || buscaLower.isNotEmpty;

    if (modoBusca) {
      return ValueListenableBuilder(
        valueListenable: _box.listenable(),
        builder: (context, Box b, _) =>
            _buildFlatSearch(b, buscaLower),
      );
    }

    return _buildTreeView(p.normalize(widget.rootPath));
  }

  Widget _buildFlatSearch(Box box, String buscaLower) {
    final resultados = <Map<String, dynamic>>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final fullPath = p.normalize((map['fullPath'] ?? '').toString());

      if (!p.isWithin(p.normalize(widget.rootPath), fullPath)) continue;

      if (map['tipo'] == 'dir') continue;

      final nome = (map['nome'] ?? '').toString();
      final base = p.basenameWithoutExtension(nome);

      if (!base.toLowerCase().startsWith(buscaLower)) continue;

      resultados.add(map);
    }

    resultados.sort((a, b) =>
        a['nome'].toString().compareTo(b['nome'].toString()));

    if (resultados.isEmpty) {
      return const Center(child: Text('Nenhum arquivo encontrado.'));
    }

    return ListView.builder(
      itemCount: resultados.length,
      itemBuilder: (context, index) => FileListItem(
        item: resultados[index],
      ),
    );
  }

  Widget _buildTreeView(String parentPath) {
    final Box box = Hive.box('minha_biblioteca');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        final String searchPath = p.normalize(parentPath);
        final items = b.values.where((item) {
          if (item is! Map) return false;
          return p.normalize(item['pai'].toString()) == searchPath;
        }).toList();

        items.sort((a, b) {
          if (a['tipo'] == b['tipo'])
            return a['nome'].toString().compareTo(b['nome'].toString());
          return a['tipo'] == 'dir' ? -1 : 1;
        });

        if (items.isEmpty) {
          return const Center(child: Text('Nenhum item encontrado.'));
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final bool isDir = item['tipo'] == 'dir';

            if (isDir) {
              final fullPath = item['fullPath'].toString();
              final nome = item['nome'].toString();
              final scheme = Theme.of(context).colorScheme;
              return ExpansionTile(
                key: PageStorageKey<String>(fullPath),
                leading: const Icon(Icons.folder, color: Colors.orangeAccent),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(nome,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: scheme.error, size: 20),
                      onPressed: () =>
                          _confirmarExclusaoSubpasta(fullPath, nome),
                      constraints: const BoxConstraints(),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
                children: [_buildTreeView(fullPath)],
              );
            }

            return FileListItem(item: item);
          },
        );
      },
    );
  }

  Widget _buildBuscaGlobal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _buscaController,
        decoration: const InputDecoration(
          hintText: 'Seleção em todos os documentos...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _textoBusca = value;
          });
        },
      ),
    );
  }
}
