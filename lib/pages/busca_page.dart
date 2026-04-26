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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Buscar Arquivo',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onPrimary, // se seu appBarTheme usar primary
          ),
        ),
        // background/foreground vêm do appBarTheme/ColorScheme
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
                FilledButton(
                  onPressed: _executarBusca,
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (!_buscou) {
      return Center(
        child: Text(
          'Digite algo e toque em Buscar.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    if (_resultados.isEmpty) {
      return Center(
        child: Text(
          'Nenhum resultado encontrado.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _resultados.length,
      itemBuilder: (context, index) {
        final item = _resultados[index];
        final tipo = (item['tipo'] ?? '').toString();
        final isFolder = tipo == 'dir' || tipo == 'folder';
        final scheme = Theme.of(context).colorScheme;

        return ListTile(
          leading: Icon(
            isFolder ? Icons.folder : Icons.description,
            color: scheme.primary,
          ),
          title: Text(item['nomeArquivo']),
          subtitle: Text(
            item['pastaPai'],
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          onTap: () => _abrirItem(item),
        );
      },
    );
  }
}
