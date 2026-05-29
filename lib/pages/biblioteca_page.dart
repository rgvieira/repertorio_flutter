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

  bool _isScanning = false;
  bool _restored = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_restored) {
        _restored = true;
        _restaurarUltimaPasta();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _escanearPasta(
    String rootPath,
    String rootId, {
    bool isRefresh = false,
  }) async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    final String rootPathNorm = p.normalize(rootPath);

    const extensoesSuportadas = [
      '.pdf',
      '.doc',
      '.docx',
      '.xls',
      '.xlsx',
      '.ppt',
      '.pptx',
      '.txt'
    ];

    try {
      final dir = Directory(rootPathNorm);
      if (!await dir.exists()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Pasta não encontrada ou inacessível.')),
          );
          setState(() => _isScanning = false);
        }
        return;
      }

      if (isRefresh) {
        final chavesParaDeletar = _box.keys.where((key) {
          final item = _box.get(key);
          return item is Map &&
              p.normalize(item['root'] ?? '') == p.normalize(rootId) &&
              item['tipo'] != 'root';
        }).toList();
        await _box.deleteAll(chavesParaDeletar);
      }

      // listSync pode falhar se encontrar pastas de sistema/restritas.
      // Usamos um try interno ou listamos de forma a ignorar erros de acesso.
      final List<FileSystemEntity> entities =
          dir.listSync(recursive: true, followLinks: false);

      final Map<String, dynamic> novosItens = {};

      for (var entity in entities) {
        try {
          final String currentPath = p.normalize(entity.path);
          final String name = p.basename(currentPath);
          final String extension = p.extension(currentPath).toLowerCase();

          if (name.startsWith('.')) continue;

          final relativePath = p.relative(currentPath, from: rootPathNorm);
          final parts = p.split(relativePath);
          if (parts.any((part) => part.startsWith('.'))) continue;

          // Filtro de extensões para arquivos
          if (entity is File && !extensoesSuportadas.contains(extension)) {
            continue;
          }

          // Pula entradas já existentes apenas se não for refresh
          if (!isRefresh && _box.containsKey(currentPath)) continue;

          final String parentPath = p.normalize(p.dirname(currentPath));

          novosItens[currentPath] = {
            'id': currentPath,
            'nome': p.basename(currentPath),
            'fullPath': currentPath,
            'pai': parentPath,
            'root': p.normalize(rootId),
            'tipo': entity is Directory ? 'dir' : 'file',
            'extensao':
                entity is File ? p.extension(currentPath).toLowerCase() : null,
          };
        } catch (e) {
          debugPrint('Pulando item devido a erro: $e');
        }
      }

      await _box.putAll(novosItens);
    } catch (e) {
      debugPrint('❌ Erro ao escanear pasta "$rootPath": $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao escanear: $e')),
        );
      }
    } finally {
      // Garante que o indicador de progresso desapareça
      if (mounted) setState(() => _isScanning = false);
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
        'fullPath': nPath, // Importante para o treeview comparar com 'pai'
        'tipo': 'root',
        'pai': 'os_root',
      });
    }

    await _escanearPasta(nPath, nPath);
  }

  void _navegarParaDetalhes(String path, String nome) {
    Hive.box('settings').put('last_biblioteca_root', path);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetalhesPastaPage(rootPath: path, folderName: nome),
      ),
    );
  }

  void _restaurarUltimaPasta() {
    final settingsBox = Hive.box('settings');
    final lastRoot = settingsBox.get('last_biblioteca_root');
    if (lastRoot == null) return;

    final item = _box.get(lastRoot);
    if (item is! Map || item['tipo'] != 'root') return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DetalhesPastaPage(
            rootPath: item['fullPath'], folderName: item['nome']),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
        ],
      ),
      floatingActionButton: kIsWeb
          ? null // Esconde na web
          : FloatingActionButton(
              onPressed: _adicionarPasta,
              child: const Icon(Icons.add),
            ),
    );
  }
}
