import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:scanpastas_flutter/widgets/file_list_item.dart';

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

  // Filtro por letra
  String _filtroLetra = 'TODOS';

  // Paginação por pasta: parentPath -> página atual
  final Map<String, int> _paginaPorPasta = {};

  static const int _pageSize = 80;

  @override
  Widget build(BuildContext context) {
    final String normalizedRoot = p.normalize(widget.rootPath);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.folderName),
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFiltroLetra(),
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: _box.listenable(),
              builder: (context, Box b, _) {
                final rootChildren = _getChildrenOf(b, normalizedRoot);

                if (rootChildren.isEmpty) {
                  return const Center(child: Text('Pasta vazia.'));
                }

                return ListView.builder(
                  itemCount: rootChildren.length,
                  itemBuilder: (context, index) {
                    final item = rootChildren[index];
                    return _buildNode(b, item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Barra de filtro A–Z + Todos
  Widget _buildFiltroLetra() {
    final letras = ['TODOS'] +
        List.generate(26, (i) => String.fromCharCode('A'.codeUnitAt(0) + i));

    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemBuilder: (context, index) {
          final letra = letras[index];
          final bool selecionado = letra == _filtroLetra;

          return ChoiceChip(
            label: Text(letra),
            selected: selecionado,
            onSelected: (_) {
              setState(() {
                _filtroLetra = letra;
                _paginaPorPasta.clear(); // reseta páginas quando troca filtro
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: letras.length,
      ),
    );
  }

  List<Map<String, dynamic>> _getChildrenOf(Box box, String parentPath) {
    final String normalizedParent = p.normalize(parentPath);

    final children = <Map<String, dynamic>>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final pai = p.normalize((map['pai'] ?? '').toString());

      if (pai != normalizedParent) continue;

      // aplica filtro por letra no NOME (sem extensão)
      final nome = (map['nome'] ?? '').toString();
      final base = p.basenameWithoutExtension(nome);
      final primeira = base.isEmpty ? '' : base[0].toUpperCase();

      if (_filtroLetra != 'TODOS' && primeira != _filtroLetra) {
        continue;
      }

      children.add(map);
    }

    children.sort((a, b) {
      final ta = a['tipo'];
      final tb = b['tipo'];

      if (ta == tb) {
        return a['nome'].toString().compareTo(b['nome'].toString());
      }
      return ta == 'dir' ? -1 : 1;
    });

    return children;
  }

  Widget _buildNode(Box box, Map<String, dynamic> item) {
    final String tipo = (item['tipo'] ?? '').toString();

    if (tipo != 'dir') {
      return FileListItem(item: item);
    }

    final String fullPath = item['fullPath'].toString();
    final String nome = item['nome'].toString();

    return ExpansionTile(
      key: PageStorageKey<String>(fullPath),
      leading: const Icon(Icons.folder, color: Colors.orangeAccent),
      title: Text(
        nome,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      children: _buildChildren(box, fullPath),
    );
  }

  List<Widget> _buildChildren(Box box, String parentPath) {
    final childrenMaps = _getChildrenOf(box, parentPath);

    if (childrenMaps.isEmpty) {
      return const [
        ListTile(
          title: Text(
            'Pasta vazia',
            style: TextStyle(
              fontStyle: FontStyle.italic,
              fontSize: 13,
            ),
          ),
        ),
      ];
    }

    // paginação por pasta
    final total = childrenMaps.length;
    final atual = _paginaPorPasta[parentPath] ?? 1;
    final maxPage = (total / _pageSize).ceil().clamp(1, 9999);
    final page = atual.clamp(1, maxPage);

    final int endIndex = (page * _pageSize).clamp(0, total);
    final visiveis = childrenMaps.sublist(0, endIndex);

    final widgets = <Widget>[
      ...visiveis.map((m) => _buildNode(box, m)),
    ];

    if (page < maxPage) {
      final restantes = total - endIndex;
      widgets.add(
        TextButton.icon(
          onPressed: () {
            setState(() {
              _paginaPorPasta[parentPath] = page + 1;
            });
          },
          icon: const Icon(Icons.expand_more),
          label: Text(
              'Carregar mais ($restantes restante${restantes > 1 ? 's' : ''})'),
        ),
      );
    }

    return widgets;
  }
}
