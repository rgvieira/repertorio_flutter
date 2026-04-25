import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

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

  String _textoBusca = '';
  final TextEditingController _buscaController = TextEditingController();

  static const int _pageSize = 80;
  int _currentPage = 1;

  @override
  void dispose() {
    _buscaController.dispose();
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
                final page = _currentPage.clamp(1, maxPage);

                final endIndex = (page * _pageSize).clamp(0, total);
                final visiveis = resultados.sublist(0, endIndex);

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
                    if (page < maxPage)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _currentPage = page + 1;
                            });
                          },
                          icon: const Icon(Icons.expand_more),
                          label: Text(
                            'Carregar mais (${total - endIndex} restante'
                            '${total - endIndex > 1 ? 's' : ''})',
                          ),
                        ),
                      ),
                  ],
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
            _currentPage = 1;
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

      // você pode ignorar "root" se quiser só arquivos/pastas internos
      // final tipo = (map['tipo'] ?? '').toString();
      // if (tipo == 'root') continue;

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

  Widget _buildItemLista(Map<String, dynamic> item) {
    final tipo = (item['tipo'] ?? '').toString();
    final fullPath = (item['fullPath'] ?? '').toString();

    // pega só o nome da pasta raiz a partir do fullPath
    String rootFolderName = '';
    if (fullPath.isNotEmpty) {
      final parts = p.normalize(fullPath).split(p.separator);
      // ignora possíveis vazios no começo (ex: caminho começando com "/")
      final nonEmpty = parts.where((e) => e.isNotEmpty).toList();
      if (nonEmpty.length >= 2) {
        // exemplo:
        // /storage/emulated/0/Partituras/Bach/arquivo.pdf
        // [storage, emulated, 0, Partituras, Bach, arquivo.pdf]
        // rootFolderName = nonEmpty[3]; // dependendo da sua estrutura
        rootFolderName = nonEmpty.first; // ou ajuste para o índice que for raiz
      }
    }

    if (tipo == 'dir') {
      return ListTile(
        leading: const Icon(Icons.folder, color: Colors.orangeAccent),
        title: Text(
          item['nome'].toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          rootFolderName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        onTap: () {
          // abrir pasta, se quiser
        },
      );
    }

    // Arquivo
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf, color: Color(0xFF186879)),
      title: Text(
        item['nome'].toString(),
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        rootFolderName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      onTap: () {
        // ou usa o seu FileListItem se preferir
        // FileListItem(item: item);
      },
    );
  }
}
