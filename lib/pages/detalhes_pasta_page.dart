import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:repertorio_flutter/widgets/file_list_item.dart';

class DetalhesPastaPage extends StatefulWidget {
  final String rootPath;
  final String folderName;

  const DetalhesPastaPage({
    super.key,
    required this.rootPath,
    required this.folderName,
  });

  @override
  State<DetalhesPastaPage> createState() => _DetalhesPastaPageState();
}

class _DetalhesPastaPageState extends State<DetalhesPastaPage> {
  final Box _box = Hive.box('minha_biblioteca');

  // busca
  String _textoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  // paginação
  static const int _pageSize = 80;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _buscaController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
        title: Text(
          widget.folderName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildBuscaGlobal(),
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

                final total = resultados.length;
                final maxPage = (total / _pageSize).ceil().clamp(1, 9999);

                return PageView.builder(
                  controller: _pageController,
                  itemCount: maxPage,
                  itemBuilder: (context, pageIndex) {
                    // pageIndex: 0-based
                    final pageNumber = pageIndex + 1;

                    final startIndex = (pageIndex * _pageSize).clamp(0, total);
                    final endIndex = (startIndex + _pageSize).clamp(0, total);

                    final visiveis = resultados.sublist(startIndex, endIndex);

                    return Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: visiveis.length,
                            itemBuilder: (context, index) {
                              final item = visiveis[index];
                              return _buildItemLista(item);
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 4,
                            horizontal: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Página $pageNumber de $maxPage '
                                '($total itens)',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Campo de busca global
  Widget _buildBuscaGlobal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _buscaController,
        decoration: const InputDecoration(
          hintText: 'Buscar em todos os documentos...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _textoBusca = value.toLowerCase();
            // ao mudar a busca, sempre volta pra primeira página
            _pageController.jumpToPage(0);
          });
        },
      ),
    );
  }

  // Busca global em TODO o box, independente de pasta/pai
  List<Map<String, dynamic>> _getResultadosGlobais(Box box) {
    final resultados = <Map<String, dynamic>>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();

      final nome = (map['nome'] ?? '').toString();
      final base = p.basenameWithoutExtension(nome);

      if (_textoBusca.isNotEmpty && !base.toLowerCase().contains(_textoBusca)) {
        continue;
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
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
        onTap: () {
          // se um dia quiser abrir a pasta, faz aqui
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
