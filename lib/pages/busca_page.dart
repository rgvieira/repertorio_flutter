import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:repertorio_flutter/pages/detalhes_pasta_page.dart';
import 'package:repertorio_flutter/pages/visualizador_pdf_page.dart';

class BuscaPage extends StatefulWidget {
  const BuscaPage({super.key});

  @override
  State<BuscaPage> createState() => _BuscaPageState();
}

class _BuscaPageState extends State<BuscaPage> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _resultados = [];
  bool _buscou = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _executarBusca() {
    final termo = _controller.text.toLowerCase().trim();
    if (termo.isEmpty) return;

    final box = Hive.box('minha_biblioteca');
    final List<Map<String, dynamic>> encontrados = [];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final nome = (map['nome'] ?? '').toString().toLowerCase();
      final fullPath = (map['fullPath'] ?? map['rootPath'] ?? '').toString();

      if (nome.contains(termo)) {
        // nome da pasta pai (diretório que contém o arquivo/pasta)
        final parentDir = fullPath.isNotEmpty
            ? p.basename(p.dirname(fullPath))
            : 'Desconhecida';

        encontrados.add({
          'pastaPai': parentDir,
          'nomeArquivo': map['nome'] ?? 'Sem nome',
          'fullPath': fullPath,
          'id': map['_id'] ?? map['id'] ?? '',
          'tipo': map['tipo'] ?? '',
        });
      }
    }

    setState(() {
      _buscou = true;
      _resultados
        ..clear()
        ..addAll(encontrados);
    });
  }

  void _abrirItem(Map<String, dynamic> item) {
    final tipo = (item['tipo'] ?? '').toString();

    if (tipo == 'dir' || tipo == 'folder') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetalhesPastaPage(
            rootPath: item['fullPath'].toString(),
            folderName: item['nomeArquivo'].toString(),
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VisualizadorPdfPage(
            filePath: item['fullPath'].toString(),
            title: item['nomeArquivo'].toString(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buscar Arquivo',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Digite o nome do arquivo ou pasta...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.search),
                    ),
                    onSubmitted: (_) => _executarBusca(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _executarBusca,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF186879),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Buscar'),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _buildResultados(),
          ),
        ],
      ),
    );
  }

  Widget _buildResultados() {
    if (!_buscou) {
      return const Center(
        child: Text(
          'Digite algo e toque em Buscar.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    if (_resultados.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum resultado encontrado.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final item = _resultados[index];
        final tipo = (item['tipo'] ?? '').toString();
        final isFolder = tipo == 'dir' || tipo == 'folder';

        return ListTile(
          leading: Icon(
            isFolder ? Icons.folder : Icons.description,
            color: const Color(0xFF186879),
          ),
          title: Text(item['nomeArquivo']), // nome do arquivo
          subtitle: Text(item['pastaPai']), // nome da pasta pai
          onTap: () => _abrirItem(item),
        );
      },
    );
  }
}
