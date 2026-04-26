import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:repertorio_flutter/pages/repertorio_page.dart'
    show RepertorioPage;
import 'package:repertorio_flutter/pages/visualizador_pdf_page.dart';
import 'package:url_launcher/url_launcher.dart';

class FileListItem extends StatelessWidget {
  final Map item;
  final VoidCallback? onViewTap;
  final VoidCallback? onLyricsTap;
  final VoidCallback? onVideoTap;
  final bool showFavorite;

  const FileListItem({
    super.key,
    required this.item,
    this.onViewTap,
    this.onLyricsTap,
    this.onVideoTap,
    this.showFavorite = true,
  });

  void _buscarLetraWeb(BuildContext context) {
    final nomeLimpo = p.basenameWithoutExtension(item['nome'].toString());
    final String query = Uri.encodeComponent('letra da música $nomeLimpo');
    final Uri url = Uri.parse('https://www.google.com/search?q=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _buscarVideoWeb(BuildContext context) {
    final nomeLimpo = p.basenameWithoutExtension(item['nome'].toString());
    final String query = Uri.encodeComponent(nomeLimpo);
    final Uri url =
        Uri.parse('https://www.youtube.com/results?search_query=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _adicionarAoRepertorio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepertorioPage(
          fileToAdd: item,
        ),
      ),
    );
  }

  IconData _getIcon() {
    final String extensao = (item['extensao'] ?? '').toString().toLowerCase();
    final String tipo = item['tipo']?.toString() ?? '';

    if (tipo == 'dir') return Icons.folder;
    if (extensao == '.pdf') return Icons.picture_as_pdf;
    if (extensao.contains('mp3') || extensao.contains('wav')) {
      return Icons.music_note;
    }
    if (extensao.contains('mp4') || extensao.contains('mkv')) {
      return Icons.movie;
    }
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final bool isDir = item['tipo'] == 'dir';
    final String nome = p.basenameWithoutExtension(item['nome'].toString());
    final scheme = Theme.of(context).colorScheme;

    // PASTA
    if (isDir) {
      return ListTile(
        dense: true,
        leading: Icon(
          _getIcon(),
          color: scheme.primary,
          size: 20,
        ),
        title: Text(
          nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    // ARQUIVO
    return ListTile(
      dense: true,
      leading: Icon(
        _getIcon(),
        color: scheme.primary,
        size: 20,
      ),
      title: Text(nome),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFavorite)
            _buildActionIcon(
              context,
              Icons.music_note,
              scheme.tertiary, // “favorito / repertório”
              () => _adicionarAoRepertorio(context),
            ),
          _buildActionIcon(
            context,
            Icons.visibility,
            scheme.primary,
            onViewTap ??
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualizadorPdfPage(
                        filePath: item['fullPath'],
                        title: nome,
                      ),
                    ),
                  );
                },
          ),
          _buildActionIcon(
            context,
            Icons.lyrics,
            scheme.secondary,
            onLyricsTap ?? () => _buscarLetraWeb(context),
          ),
          _buildActionIcon(
            context,
            Icons.play_circle_fill,
            scheme.error, // continua chamando atenção como “ação vermelha”
            onVideoTap ?? () => _buscarVideoWeb(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(
    BuildContext context,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return IconButton(
      icon: Icon(icon, color: color, size: 20),
      onPressed: onTap,
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }
}
