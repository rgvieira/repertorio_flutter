import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
// Importe o arquivo da nova página aqui:
import 'detalhes_pasta_page.dart';

class BibliotecaPage extends StatefulWidget {
  const BibliotecaPage({super.key});

  @override
  State<BibliotecaPage> createState() => _BibliotecaPageState();
}

class _BibliotecaPageState extends State<BibliotecaPage> {
  final Box _box = Hive.box('minha_biblioteca');
  bool _isScanning = false;

  // --- FERRAMENTA DE INSPEÇÃO DO HIVE ---
  void _debugPrintHive() {
    print("\n--- 🔎 INSPEÇÃO DE DADOS NO HIVE ---");
    if (_box.isEmpty) {
      print("Status: O banco está vazio.");
    } else {
      print("Total de chaves no banco: ${_box.length}");
      for (var key in _box.keys) {
        var item = _box.get(key);
        if (item is Map) {
          print(
              "Chave: $key | Nome: ${item['nome']} | Pai: ${item['pai']} | Tipo: ${item['tipo']}");
        }
      }
    }
    print("--- 🔎 FIM DA INSPEÇÃO ---\n");
  }

  // --- ESCANEAMENTO COM LOGS ---
  Future<void> _escanearPasta(String rootPath, String rootId,
      {bool isRefresh = false}) async {
    if (!mounted) return;
    setState(() => _isScanning = true);

    print("🚀 Iniciando Scan: $rootPath");

    try {
      final dir = Directory(rootPath);
      if (!await dir.exists()) {
        print("❌ Erro: O diretório não existe fisicamente.");
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

      // listSync lê os arquivos (agora com permissão total)
      final List<FileSystemEntity> entities =
          dir.listSync(recursive: true, followLinks: false);
      print("📦 Itens detectados pelo Sistema: ${entities.length}");

      Map<String, dynamic> novosItens = {};

      for (var entity in entities) {
        final String currentPath = p.normalize(entity.path);
        final String parentPath = p.normalize(p.dirname(currentPath));

        novosItens[currentPath] = {
          "id": currentPath,
          "nome": p.basename(currentPath),
          "fullPath": currentPath,
          "pai": parentPath,
          "root": rootId,
          "tipo": entity is Directory ? 'dir' : 'file',
          "extensao":
              entity is File ? p.extension(currentPath).toLowerCase() : null,
        };
      }

      await _box.putAll(novosItens);
      print("✅ Escaneamento concluído.");
    } catch (e) {
      print("☢️ Falha no Scan: $e");
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  // --- ADICIONAR PASTA COM PEDIDO DE PERMISSÃO ---
  Future<void> _adicionarPasta() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    }

    String? path = await FilePicker.getDirectoryPath();
    if (path != null) {
      final String nPath = p.normalize(path);
      if (!_box.containsKey(nPath)) {
        await _box.put(nPath, {
          "id": nPath,
          "nome": p.basename(nPath),
          "fullPath": nPath,
          "tipo": "root",
          "pai": "os_root",
          "favorita": _box.values
              .where((item) => item is Map && item['tipo'] == 'root')
              .isEmpty, // se for a primeira, já é favorita
        });
      }
      await _escanearPasta(nPath, nPath);

      // se for a primeira pasta de verdade, marcar como favorita
      final raizes = _box.values
          .where((item) => item is Map && item['tipo'] == 'root')
          .toList();
      if (raizes.length == 1) {
        final item = raizes.first;
        final id = item['id'].toString();
        await _box.put(id, {
          ...item,
          'favorita': true,
        });
        if (mounted) setState(() {});
      }
    }
  }

  // --- NAVEGAÇÃO PARA A TELA DE DETALHES (TABS) ---
  void _navegarParaDetalhes(String path, String nome) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            DetalhesPastaPage(rootPath: path, folderName: nome),
      ),
    );
  }

  void _toggleFavorita(String idPasta) async {
    // recolhe todas as pastas raiz
    final List<String> todas = _box.keys
        .where((k) => _box.get(k) is Map && _box.get(k)['tipo'] == 'root')
        .map((k) => k.toString())
        .toList();

    // actualiza 1 por vez (sem transação, Hive padrão)
    for (final key in todas) {
      final item = _box.get(key);
      if (item is Map) {
        final novo = Map<String, dynamic>.from(item);
        novo['favorita'] = (key == idPasta);
        await _box.put(key, novo);
      }
    }

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          if (_isScanning) const LinearProgressIndicator(color: Colors.orange),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box box, _) {
                final pastasRaiz = box.values
                    .where((item) => item is Map && item['tipo'] == 'root')
                    .toList();

                if (pastasRaiz.isEmpty) {
                  return const Center(child: Text("Nenhuma pasta mapeada."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: pastasRaiz.length,
                  itemBuilder: (context, index) {
                    final item = pastasRaiz[index];
                    final bool isFav = item['favorita'] ?? false;

                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        onTap: () => _navegarParaDetalhes(
                            item['fullPath'], item['nome']),
                        leading: Icon(
                          isFav ? Icons.star : Icons.folder,
                          color: isFav
                              ? Colors.orangeAccent
                              : const Color(0xFF186879),
                          size: 30,
                        ),
                        title: Text(
                          item['nome'],
                          style: TextStyle(
                            fontWeight:
                                isFav ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                isFav ? Icons.star : Icons.star_border,
                                color:
                                    isFav ? Colors.orangeAccent : Colors.orange,
                              ),
                              onPressed: () => _toggleFavorita(item['id']),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh,
                                  color: Colors.green),
                              onPressed: () => _escanearPasta(
                                item['fullPath'],
                                item['id'],
                                isRefresh: true,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_forever,
                                  color: Colors.red),
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
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarPasta,
        backgroundColor: const Color(0xFF186879),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _confirmarExclusao(String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Remover Pasta?"),
        content: const Text("Isso apagará o índice dos arquivos no app."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar")),
          TextButton(
            onPressed: () {
              final keys = _box.keys.where((k) {
                final i = _box.get(k);
                return k == id || (i is Map && i['root'] == id);
              }).toList();
              _box.deleteAll(keys);
              Navigator.pop(context);
            },
            child: const Text("Remover", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
