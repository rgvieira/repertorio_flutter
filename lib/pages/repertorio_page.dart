// pages/repertorio_page.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repertorio_flutter/pages/musicas_repertorio_page.dart';

class RepertorioPage extends StatefulWidget {
  final Map? fileToAdd; // null = modo normal, !null = modo seleção

  const RepertorioPage({super.key, this.fileToAdd});

  @override
  State<RepertorioPage> createState() => _RepertorioPageState();
}

class _RepertorioPageState extends State<RepertorioPage> {
  final TextEditingController _controller = TextEditingController();
  final Box _box = Hive.box('minha_biblioteca');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.fileToAdd != null) {
        _showAddToRepertorioDialog(widget.fileToAdd!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isSelecao = widget.fileToAdd != null;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Input Box - CRIAR REPERTÓRIO
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Nome do repertório...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _saveRepertorio,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF186879),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'CRIAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
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

  // ---------------- FAVORITO: marcar/desmarcar ----------------

  Future<void> _toggleFavoritoRepertorio(Map repertorio) async {
    final String id = repertorio['_id'].toString();

    // Clona o map atual
    final Map<String, dynamic> repoAtual =
        Map<String, dynamic>.from(repertorio);

    final bool jaFavorito = repoAtual['favoritoRepertorio'] == true;

    // Se já é favorito, desmarca
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

    // Se NÃO é favorito, precisamos:
    // 1) desmarcar qualquer outro repertório favorito
    // 2) marcar este como favorito
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

  /// Diálogo para escolher em qual repertório adicionar o arquivo (modo seleção)
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
              Navigator.pop(context); // fecha o diálogo
              if (widget.fileToAdd != null) {
                Navigator.pop(this.context); // volta para quem chamou
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

      // fecha o diálogo
      Navigator.pop(context);

      // se veio de favorito, sai também da RepertorioPage
      if (widget.fileToAdd != null) {
        Navigator.pop(this.context);
      }

      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          SnackBar(content: Text('Adicionado a "${repertorio['nome']}"')),
        );
      }
    } else {
      Navigator.pop(context); // fecha o diálogo
      if (mounted) {
        ScaffoldMessenger.of(this.context).showSnackBar(
          const SnackBar(content: Text('Já está neste repertório')),
        );
      }
    }
  }

  // ---------------- LISTA DE REPERTÓRIOS ----------------

  Widget _buildRepertoriosList(Box box) {
    final List<Map> repertorios = box.values
        .where((item) =>
            item is Map &&
            (item['type'] == 'repertorio' || item['tipo'] == 'repertorio'))
        .cast<Map>()
        .toList();

    if (repertorios.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum repertório criado. Inicialmente acesse Biblioteca e inclua uma pasta.',
          style: TextStyle(
            color: Colors.grey,
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

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(10),
            leading: const Icon(
              Icons.queue_music,
              color: Color(0xFF186879),
            ),
            title: Text(
              nome,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF186879),
              ),
            ),
            subtitle: Text(
              '$qtd incluído(s)',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // botão favorito
                IconButton(
                  onPressed: () => _toggleFavoritoRepertorio(repertorio),
                  icon: Icon(
                    favorito ? Icons.star : Icons.star_border,
                    color: favorito ? Colors.orangeAccent : Colors.orange,
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
                  icon: const Icon(Icons.receipt_long),
                  tooltip: 'Ver Músicas',
                ),
                IconButton(
                  onPressed: () => _deleteRepertorio(repertorio),
                  icon: const Icon(Icons.delete, color: Colors.red),
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
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Digite um nome!')),
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
        const SnackBar(
          content: Text('Repertório já cadastrado.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final id = 'rep_${DateTime.now().millisecondsSinceEpoch}';

      // vê se já existe algum repertório na base
      final bool jaTemAlgumRepertorio = _box.values.any((item) =>
          item is Map &&
          (item['type'] == 'repertorio' || item['tipo'] == 'repertorio'));

      await _box.put(id, {
        '_id': id,
        'type': 'repertorio',
        'nome': nome,
        'musicas': <String>[],
        // se for o primeiro, já começa como favorito
        'favoritoRepertorio': !jaTemAlgumRepertorio,
      });

      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Repertório criado!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro ao salvar!')),
      );
    }
  }

  Future<void> _deleteRepertorio(Map repertorio) async {
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
            child: const Text('Excluir', style: TextStyle(color: Colors.red)),
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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
