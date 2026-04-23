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

  // Filtro por grupo de caracteres
  // Grupos: TODOS, números e faixas de letras
  final List<String> _grupos = ['TODOS', '0-9', 'A-F', 'G-L', 'M-R', 'S-Z'];
  String _filtroGrupo = 'TODOS';

  // Busca por texto livre
  String _textoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  // Paginação por pasta: parentPath -> página atual
  final Map<String, int> _paginaPorPasta = {};

  static const int _pageSize = 80;

  @override
  void dispose() {
    _buscaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String normalizedRoot = p.normalize(widget.rootPath);

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
          _buildFiltroGrupo(),
          _buildBuscaLocal(),
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

  // Barra de filtro por grupos de caracteres
  Widget _buildFiltroGrupo() {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: _grupos.length,
        itemBuilder: (context, index) {
          final grupo = _grupos[index];
          final bool selecionado = grupo == _filtroGrupo;

          return ChoiceChip(
            label: Text(grupo),
            selected: selecionado,
            onSelected: (_) {
              setState(() {
                _filtroGrupo = grupo;
                _paginaPorPasta.clear(); // reseta paginação ao mudar filtro
              });
            },
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 6),
      ),
    );
  }

  // Campo de busca por texto livre (nome do arquivo/pasta)
  Widget _buildBuscaLocal() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: TextField(
        controller: _buscaController,
        decoration: const InputDecoration(
          hintText: 'Filtrar por nome...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (value) {
          setState(() {
            _textoBusca = value.toLowerCase();
            _paginaPorPasta.clear(); // reseta páginas quando muda busca
          });
        },
      ),
    );
  }

  // Verifica se a primeira letra pertence ao grupo selecionado
  bool _pertenceAoGrupo(String grupo, String primeira) {
    if (grupo == 'TODOS') return true;

    if (grupo == '0-9') {
      return primeira.compareTo('0') >= 0 && primeira.compareTo('9') <= 0;
    }

    switch (grupo) {
      case 'A-F':
        return primeira.compareTo('A') >= 0 && primeira.compareTo('F') <= 0;
      case 'G-L':
        return primeira.compareTo('G') >= 0 && primeira.compareTo('L') <= 0;
      case 'M-R':
        return primeira.compareTo('M') >= 0 && primeira.compareTo('R') <= 0;
      case 'S-Z':
        return primeira.compareTo('S') >= 0 && primeira.compareTo('Z') <= 0;
      default:
        return true;
    }
  }

  // Retorna filhos diretos de parentPath, aplicando:
  // - filtro por grupo (A-F, 0-9, etc.)
  // - filtro por texto (qualquer parte do nome)
  List<Map<String, dynamic>> _getChildrenOf(Box box, String parentPath) {
    final String normalizedParent = p.normalize(parentPath);
    final children = <Map<String, dynamic>>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final pai = p.normalize((map['pai'] ?? '').toString());

      if (pai != normalizedParent) continue;

      final nome = (map['nome'] ?? '').toString();
      final base = p.basenameWithoutExtension(nome);
      final primeira = base.isEmpty ? '' : base[0].toUpperCase();

      // Filtro por grupo (A-F, 0-9, etc.)
      if (!_pertenceAoGrupo(_filtroGrupo, primeira)) {
        continue;
      }

      // Filtro por texto livre
      if (_textoBusca.isNotEmpty &&
          !base.toLowerCase().contains(_textoBusca)) {
        continue;
      }

      children.add(map);
    }

    // Ordena: diretórios primeiro, depois arquivos, ambos por nome
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