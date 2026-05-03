import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repertorio_flutter/pages/musicas_repertorio_page.dart';
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';

class RepertorioPage extends StatefulWidget {
  final Map? fileToAdd; // null = modo normal, !null = modo seleção

  const RepertorioPage({super.key, this.fileToAdd});

  @override
  State<RepertorioPage> createState() => _RepertorioPageState();
}

class _RepertorioPageState extends State<RepertorioPage> {
  final TextEditingController _controller = TextEditingController();
  final Box _box = Hive.box('minha_biblioteca');
  BannerAdManager? _bannerAdManager;
  bool _isScanning = false;

  bool _adLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fileToAdd != null) {
        _showAddToRepertorioDialog(widget.fileToAdd!);
      }
    });
    if (!_adLoaded) {
      if (!kIsWeb) {
        _bannerAdManager = BannerAdManager();
        _bannerAdManager!.loadBanner();
      }
    }
  }

  @override
  void dispose() {
    _bannerAdManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Box - CRIAR REPERTÓRIO
            Card(
              margin: EdgeInsets.zero,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nome do repertório...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                      ),
                      onPressed: _saveRepertorio,
                      child: const Text(
                        'CRIAR',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  // Adiciona o banner no final
                  if (!kIsWeb && _bannerAdManager != null)
                    _bannerAdManager!.buildBannerWidget()
                  else
                    const SizedBox.shrink(),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Lista de Repertórios
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: _box.listenable(),
                builder: (context, Box box, _) {
                  return _buildRepertoriosList(box);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- FAVORITO: marcar/desmarcar ----------------

  Future<void> _toggleFavoritoRepertorio(Map repertorio) async {
    final String id = repertorio['_id'].toString();

    final Map<String, dynamic> repoAtual =
        Map<String, dynamic>.from(repertorio);

    final bool jaFavorito = repoAtual['favoritoRepertorio'] == true;

    if (jaFavorito) {
      repoAtual['favoritoRepertorio'] = false;
      await _box.put(id, repoAtual);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${repoAtual['nome']}" removido dos favoritos'),
          ),
        );
      }
      return;
    }

    for (final raw in _box.values) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();
      final type = (map['type'] ?? map['tipo'])?.toString();
      if (type == 'repertorio' && map['favoritoRepertorio'] == true) {
        final String otherId = map['_id'].toString();
        final novoMap = Map<String, dynamic>.from(map);
        novoMap['favoritoRepertorio'] = false;
        await _box.put(otherId, novoMap);
      }
    }

    repoAtual['favoritoRepertorio'] = true;
    await _box.put(id, repoAtual);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${repoAtual['nome']}" marcado como favorito'),
        ),
      );
    }
  }

  // ---------------- DIÁLOGO: adicionar arquivo a repertório ----------------

  void _showAddToRepertorioDialog(Map arquivo) {
    final List<Map> repertorios = _box.values
        .where((item) =>
            item is Map &&
            (item['type'] == 'repertorio' || item['tipo'] == 'repertorio'))
        .cast<Map>()
        .toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Adicionar "${arquivo['nome']}"'),
        content: SizedBox(
          height: 300,
          width: double.maxFinite,
          child: repertorios.isEmpty
              ? const Center(child: Text('Crie um repertório primeiro'))
              : ListView.builder(
                  itemCount: repertorios.length,
                  itemBuilder: (context, index) {
                    final repo = repertorios[index];
                    return ListTile(
                      leading: const Icon(Icons.music_note),
                      title: Text(repo['nome']),
                      trailing: const Icon(Icons.add, color: Colors.green),
                      onTap: () => _adicionarArquivoAoRepertorio(repo, arquivo),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (widget.fileToAdd != null) {
                Navigator.pop(this.context);
              }
            },
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _adicionarArquivoAoRepertorio(
      Map repertorio, Map arquivo) async {
    final String repoId = repertorio['_id'].toString();
    final Map<String, dynamic> repoAtual =
        Map<String, dynamic>.from(repertorio);
    List<dynamic> musicas = repoAtual['musicas'] ?? [];

    final arquivoId = arquivo['id'].toString();
    if (!musicas.contains(arquivoId)) {
      musicas.add(arquivoId);
      repoAtual['musicas'] = musicas;
      await _box.put(repoId, repoAtual);

      Navigator.pop(context);

      if (widget.fileToAdd != null) {
        Navigator.pop(this.context);
      }

      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Adicionado a "${repertorio['nome']}"')),
        );
      }
    } else {
      Navigator.pop(context);
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Já está neste repertório')),
        );
      }
    }
  }

  // ---------------- LISTA DE REPERTÓRIOS ----------------

  Widget _buildRepertoriosList(Box box) {
    final scheme = Theme.of(context).colorScheme;

    final List<Map> repertorios = box.values
        .where((item) =>
            item is Map &&
            (item['type'] == 'repertorio' || item['tipo'] == 'repertorio'))
        .cast<Map>()
        .toList();

    if (repertorios.isEmpty) {
      return Center(
        child: Text(
          'Nenhum repertório criado. Inicialmente acesse Biblioteca e inclua uma pasta.',
          style: TextStyle(
            color: scheme.onSurfaceVariant,
            fontSize: 16,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    repertorios.sort((a, b) =>
        (a['nome'] ?? '').toString().compareTo((b['nome'] ?? '').toString()));

    return ListView.separated(
      itemCount: repertorios.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final repertorio = repertorios[index];
        final nome = repertorio['nome']?.toString() ?? 'Sem nome';
        final musicas = repertorio['musicas'] as List? ?? [];
        final qtd = musicas.length;
        final bool favorito = repertorio['favoritoRepertorio'] == true;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: Icon(
              Icons.queue_music,
              color: scheme.primary,
            ),
            title: Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$qtd incluído(s)'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _toggleFavoritoRepertorio(repertorio),
                  icon: Icon(
                    favorito ? Icons.star : Icons.star_border,
                    color:
                        favorito ? scheme.tertiary : scheme.tertiaryContainer,
                  ),
                  tooltip: 'Marcar como favorito',
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MusicasRepertorioPage(
                          repertorioId: repertorio['_id'],
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.receipt_long, color: scheme.primary),
                  tooltip: 'Ver Músicas',
                ),
                IconButton(
                  onPressed: () => _deleteRepertorio(repertorio),
                  icon: Icon(Icons.delete, color: scheme.error),
                  tooltip: 'Excluir',
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------------- CRIAR / EXCLUIR REPERTÓRIO ----------------

  Future<void> _saveRepertorio() async {
    final nome = _controller.text.trim();
    final scheme = Theme.of(context).colorScheme;

    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Informe um nome para o repertório.'),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    final List<Map> repertoriosExistentes = _box.values
        .where((item) =>
            item is Map &&
            (item['type'] == 'repertorio' || item['tipo'] == 'repertorio') &&
            item['nome'].toString().toLowerCase() == nome.toLowerCase())
        .cast<Map>()
        .toList();

    if (repertoriosExistentes.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Repertório já cadastrado.'),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    try {
      final id = 'rep_${DateTime.now().millisecondsSinceEpoch}';

      final bool jaTemAlgumRepertorio = _box.values.any((item) =>
          item is Map &&
          (item['type'] == 'repertorio' || item['tipo'] == 'repertorio'));

      await _box.put(id, {
        '_id': id,
        'type': 'repertorio',
        'nome': nome,
        'musicas': <String>[],
        'favoritoRepertorio': !jaTemAlgumRepertorio,
      });

      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Repertório criado!'),
          backgroundColor: scheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar!')),
      );
    }
  }

  Future<void> _deleteRepertorio(Map repertorio) async {
    final scheme = Theme.of(context).colorScheme;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Repertório'),
        content: Text('Deseja excluir "${repertorio['nome']}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Excluir',
              style: TextStyle(color: scheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _box.delete(repertorio['_id']);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Repertório excluído!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao excluir!')),
        );
      }
    }
  }
}
