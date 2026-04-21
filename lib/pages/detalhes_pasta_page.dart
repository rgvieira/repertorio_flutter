import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:scanpastas_flutter/widgets/file_list_item.dart';
import 'package:url_launcher/url_launcher.dart'; // IMPORTANTE: flutter pub add url_launcher
import 'visualizador_pdf_page.dart';

class DetalhesPastaPage extends StatelessWidget {
  final String rootPath;
  final String folderName;

  const DetalhesPastaPage(
      {super.key, required this.rootPath, required this.folderName});

  // FUNÇÃO PARA BUSCAR LETRA NO GOOGLE
  void _buscarLetraWeb(String nomeArquivo) async {
    final nomeLimpo = p.basenameWithoutExtension(nomeArquivo);
    final String query = Uri.encodeComponent("letra da música $nomeLimpo");
    final Uri url = Uri.parse("https://www.google.com/search?q=$query");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Erro ao abrir busca");
    }
  }

  // FUNÇÃO PARA BUSCAR VÍDEO NO YOUTUBE
  void _buscarVideoWeb(String nomeArquivo) async {
    final nomeLimpo = p.basenameWithoutExtension(nomeArquivo);
    final String query = Uri.encodeComponent(nomeLimpo);
    final Uri url =
        Uri.parse("https://www.youtube.com/results?search_query=$query");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      print("Erro ao abrir YouTube");
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(folderName),
          backgroundColor: const Color(0xFF186879),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.account_tree), text: "Arquivos"),
              Tab(icon: Icon(Icons.star), text: "Favoritos"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildTreeView(p.normalize(rootPath)),
            const Center(child: Text("Sincronizando Repertórios...")),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeView(String parentPath) {
    final Box box = Hive.box('minha_biblioteca');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        final String searchPath = p.normalize(parentPath);
        final items = b.values.where((item) {
          if (item is! Map) return false;
          return p.normalize(item['pai'].toString()) == searchPath;
        }).toList();

        // Ordenação: Pasta antes de Arquivo
        items.sort((a, b) {
          if (a['tipo'] == b['tipo'])
            return a['nome'].toString().compareTo(b['nome'].toString());
          return a['tipo'] == 'dir' ? -1 : 1;
        });

        return ListView.builder(
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final bool isDir = item['tipo'] == 'dir';

            if (isDir) {
              return ExpansionTile(
                leading: const Icon(Icons.folder, color: Colors.orangeAccent),
                title: Text(item['nome'],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                children: [_buildTreeView(item['fullPath'])],
              );
            } else {
              return FileListItem(item: item);
            }
          },
        );
      },
    );
  }

  Widget _buildActionIcon(IconData icon, Color color, VoidCallback onTap) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
