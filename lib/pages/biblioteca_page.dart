import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';
import 'detalhes_pasta_page.dart';

class BibliotecaPage extends StatefulWidget {
  const BibliotecaPage({super.key});

  @override
  State<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends State<BibliotecaPage> {
  final Box _box = Hive.box('minha_biblioteca');

  final BannerAdManager _bannerAdManager = BannerAdManager();
  bool _isScanning = false;

  bool _adLoaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_adLoaded) {
      _bannerAdManager.loadBanner(context);
      _adLoaded = true;
    }
  }

  @override
  void dispose() {
    _bannerAdManager.dispose();
    super.dispose();
  }

  Future<void> _escanearPasta(
    String rootPath,
    String rootId, {
    bool isRefresh = false,
  }) async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    try {
      final dir = Directory(rootPath);
      if (!await dir.exists()) {
        return;
      }

      if (isRefresh) {
        final chavesParaDeletar = _box.keys.where((key) {
          final item = _box.get(key);
          return item is Map &&
              item['root'] == rootId &&
              item['tipo'] != 'root';
        }).toList();
        await _box.deleteAll(chavesParaDeletar);
      }

      final List<FileSystemEntity> entities =
          dir.listSync(recursive: true, followLinks: false);

      final Map<String, dynamic> novosItens = {};

      for (var entity in entities) {
        final String currentPath = p.normalize(entity.path);

        // Pula entradas já existentes para evitar duplicatas de fullPath
        if (!isRefresh && _box.containsKey(currentPath)) continue;

        final String parentPath = p.normalize(p.dirname(currentPath));

        novosItens[currentPath] = {
          'id': currentPath,
          'nome': p.basename(currentPath),
          'fullPath': currentPath,
          'pai': parentPath,
          'root': rootId,
          'tipo': entity is Directory ? 'dir' : 'file',
          'extensao':
              entity is File ? p.extension(currentPath).toLowerCase() : null,
        };
      }

      await _box.putAll(novosItens);
    } catch (e) {
      debugPrint('❌ Erro ao escanear pasta "$rootPath": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao escanear: $e')),
        );
      }
    }
  }

  Future<void> _adicionarPasta() async {
    if (!kIsWeb && Platform.isAndroid) {
      // Tenta permission.storage (READ_EXTERNAL_STORAGE) primeiro.
      // Funciona no Android 9-10 com dialog normal.
      // No Android 11+ é ignorado/negado automaticamente.
      var status = await Permission.storage.request();

      // Se negado, tenta manageExternalStorage (Android 11+).
      if (!status.isGranted) {
        status = await Permission.manageExternalStorage.request();
      }

      if (!status.isGranted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permissão de armazenamento necessária.'),
          ),
        );
        return;
      }
    }

    final String? path = await FilePicker.getDirectoryPath();
    if (path == null) return;

    final String nPath = p.normalize(path);

    if (!_box.containsKey(nPath)) {
      await _box.put(nPath, {
        'id': nPath,
        'nome': p.basename(nPath),
        'fullPath': nPath,
        'tipo': 'root',
        'pai': 'os_root',

      });
    }

    await _escanearPasta(nPath, nPath);
  }

  void _navegarParaDetalhes(String path, String nome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetalhesPastaPage(rootPath: path, folderName: nome),
      ),
    );
  }

  void _confirmarExclusao(String id) {
    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover pasta?'),
        content: const Text('Isso apagará o índice dos arquivos no app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              final keys = _box.keys.where((k) {
                final i = _box.get(k);
                return k == id || (i is Map && i['root'] == id);
              }).toList();
              _box.deleteAll(keys);
              Navigator.pop(context);
            },
            child: Text(
              'Remover',
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Column(
        children: [
          if (_isScanning) LinearProgressIndicator(color: scheme.tertiary),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                final pastasRaiz = box.values
                    .where((item) => item is Map && item['tipo'] == 'root')
                    .toList();

                if (pastasRaiz.isEmpty) {
                  return Center(
                    child: Text(
                      'Inclua uma pasta para iniciar.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pastasRaiz.length,
                  itemBuilder: (context, index) {
                    final item = pastasRaiz[index];

                    return Card(
                      elevation: 1,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _navegarParaDetalhes(
                          item['fullPath'],
                          item['nome'],
                        ),
                        leading: Icon(
                          Icons.folder,
                          color: scheme.primary,
                          size: 30,
                        ),
                        title: Text(
                          item['nome'],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.refresh,
                                color: scheme.primary,
                              ),
                              onPressed: () => _escanearPasta(
                                item['fullPath'],
                                item['id'],
                                isRefresh: true,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.delete_forever,
                                color: scheme.error,
                              ),
                              onPressed: () => _confirmarExclusao(item['id']),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // Adiciona o banner no final
          _bannerAdManager.buildBannerWidget(),
        ],
      ),
// No build() onde tem o FloatingActionButton ou botão de adicionar:

      floatingActionButton: kIsWeb
          ? null // Esconde na web
          : FloatingActionButton(
              onPressed: _adicionarPasta,
              child: const Icon(Icons.add),
            ),
    );
  }
}
