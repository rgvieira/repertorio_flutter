import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
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

  // Controle de Navegação
  late String _currentPath;

  // busca
  String _textoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  // Lote de processamento (otimização interna)
  static const int _pageSize = 80;

  @override
  void initState() {
    super.initState();
    _currentPath = widget.rootPath;
  }

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
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
                color: scheme.onPrimary, // ou null para usar padrão do AppBar
              ),
            ),
            if (_currentPath != widget.rootPath)
              Text(
                p.relative(_currentPath, from: widget.rootPath),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onPrimary.withAlpha(204), // 0.8 * 255 ≈ 204
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildBuscaGlobal(),
          if (_textoBusca.isEmpty && _currentPath != widget.rootPath)
            _buildBotaoVoltar(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box b, _) {
                final resultados = _getResultadosGlobais(b);

                if (resultados.isEmpty) {
                  return const Center(
                    child: Text('Nenhum item encontrado.'),
                  );
                }

                return ListView.builder(
                  itemCount: resultados.length,
                  itemBuilder: (context, index) =>
                      _buildItemLista(resultados[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotaoVoltar() {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      tileColor: scheme.surfaceContainerHighest.withOpacity(0.5),
      leading: const Icon(Icons.arrow_upward, color: Colors.blueGrey),
      title: const Text('.. (Voltar para pasta anterior)',
          style: TextStyle(fontWeight: FontWeight.bold)),
      onTap: () {
        setState(() {
          _currentPath = p.dirname(_currentPath);
        });
      },
    );
  }

  // Campo de busca global
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
            _textoBusca = value.toLowerCase();
          });
        },
      ),
    );
  }

  List<Map<String, dynamic>> _getResultadosGlobais(Box box) {
    final resultados = <Map<String, dynamic>>[];
    final buscaLower = _textoBusca.trim().toLowerCase();

    // Modo flat: relação completa de arquivos sem hierarquia de pastas
    final modoFlat = widget.alwaysFlat || buscaLower.isNotEmpty;

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final fullPath = (map['fullPath'] ?? '').toString();
      final nome = (map['nome'] ?? '').toString();

      if (modoFlat) {
        // MODO BUSCA: Procura em todos os subníveis da raiz favorita
        if (!p.isWithin(widget.rootPath, fullPath)) continue;

        // Em modo flat, ocultamos diretórios para exibir apenas a relação de arquivos
        if (map['tipo'] == 'dir') continue;

        final base = p.basenameWithoutExtension(nome);
        // Filtra apenas nomes que COMEÇAM com os caracteres informados
        if (!base.toLowerCase().startsWith(buscaLower)) {
          continue;
        }
      } else {
        // MODO NAVEGAÇÃO: Apenas filhos imediatos da pasta atual
        final pai = p.dirname(fullPath);
        if (pai != _currentPath) continue;
        if (fullPath == widget.rootPath) continue;
      }

      resultados.add(map);
    }

    // Ordena: diretórios primeiro, depois arquivos, ambos por nome
    resultados.sort((a, b) {
      final ta = a['tipo'];
      final tb = b['tipo'];

      if (ta == tb) {
        return a['nome'].toString().compareTo(b['nome'].toString());
      }
      return ta == 'dir' ? -1 : 1;
    });

    return resultados;
  }

  // MONTA O ITEM DA LISTA
  Widget _buildItemLista(Map<String, dynamic> item) {
    final tipo = (item['tipo'] ?? '').toString();
    final fullPath = (item['fullPath'] ?? '').toString();

    // ----- SUBTÍTULO (caminho abaixo de Documents/Downloads/etc.) -----
    String subtitle = '';
    if (tipo != 'dir' && fullPath.isNotEmpty) {
      final directory = p.dirname(fullPath);
      final parts = p.split(p.normalize(directory));

      final roots = [
        'documents',
        'documentos',
        'download',
        'downloads',
        'music',
        'musics',
        'música',
        'musicas',
        'movies',
        'videos',
        'pictures',
        'imagens',
        'dcim',
      ];

      int rootIndex = -1;
      for (int i = 0; i < parts.length; i++) {
        final partLower = parts[i].toLowerCase();
        if (roots.contains(partLower)) {
          rootIndex = i;
        }
      }

      if (rootIndex != -1 && rootIndex + 1 < parts.length) {
        final subPathParts = parts.sublist(rootIndex + 1);
        subtitle = subPathParts.join(' / ');
      } else if (parts.length >= 2) {
        subtitle = parts.sublist(parts.length - 2).join(' / ');
      } else if (parts.isNotEmpty) {
        subtitle = parts.last;
      }
    }

    // PASTA: ListTile simples (sem botões)
    if (tipo == 'dir') {
      return ListTile(
        leading: const Icon(Icons.folder, color: Colors.orangeAccent),
        title: Text(
          (item['nome'] ?? '').toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: subtitle.isEmpty
            ? null
            : Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
        onTap: () {
          setState(() {
            _currentPath = fullPath;
          });
        },
      );
    }

    // ARQUIVO: usa FileListItem (ícone + nome sem extensão + botões)
    return FileListItem(
      item: item,
      // se quiser no futuro, dá pra adaptar FileListItem para receber "subtitle"
    );
  }
}
