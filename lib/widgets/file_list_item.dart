import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

import 'package:scanpastas_flutter/pages/visualizador_pdf_page.dart';
import 'package:scanpastas_flutter/pages/repertorio_page.dart';

class FileListItem extends StatelessWidget {
  final Map item;
  final VoidCallback? onViewTap;
  final VoidCallback? onLyricsTap;
  final VoidCallback? onVideoTap;
  final bool showFavorite; // nova flag

  const FileListItem({
    super.key,
    required this.item,
    this.onViewTap,
    this.onLyricsTap,
    this.onVideoTap,
    this.showFavorite = true, // default = true
  });

  // FUNÇÃO PARA BUSCAR LETRA NO GOOGLE
  void _buscarLetraWeb(BuildContext context) {
    final nomeLimpo = p.basenameWithoutExtension(item['nome'].toString());
    final String query = Uri.encodeComponent('letra da música $nomeLimpo');
    final Uri url = Uri.parse('https://www.google.com/search?q=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // FUNÇÃO PARA BUSCAR VÍDEO NO YOUTUBE
  void _buscarVideoWeb(BuildContext context) {
    final nomeLimpo = p.basenameWithoutExtension(item['nome'].toString());
    final String query = Uri.encodeComponent(nomeLimpo);
    final Uri url =
        Uri.parse('https://www.youtube.com/results?search_query=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  // Abre lista de repertórios para adicionar
  void _adicionarAoRepertorio(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepertorioPage(
          fileToAdd: item, // Passa o arquivo selecionado
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
  @override
  Widget build(BuildContext context) {
    final bool isDir = item['tipo'] == 'dir';
    final String nome = p.basenameWithoutExtension(item['nome'].toString());

    // PASTA: só ícone + nome, sem trailing
    if (isDir) {
      return ListTile(
        dense: true,
        leading: Icon(
          _getIcon(), // folder
          color: Colors.blueGrey,
          size: 20,
        ),
        title: Text(
          nome,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
    }

    // ARQUIVO: ícone + nome + botões
    return ListTile(
      dense: true,
      leading: Icon(
        _getIcon(),
        color: Colors.blueGrey,
        size: 20,
      ),
      title: Text(nome),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showFavorite)
            _buildActionIcon(
              Icons.music_note,
              Colors.amber,
              () => _adicionarAoRepertorio(context),
            ),
          _buildActionIcon(
            Icons.visibility,
            Colors.green,
            onViewTap ??
                () {
      // LOGA O FULLPATH ANTES DE ABRIR
                     
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
            Icons.lyrics,
            Colors.blue,
            () => _buscarLetraWeb(context),
          ),
          _buildActionIcon(
            Icons.play_circle_fill,
            Colors.red,
            () => _buscarVideoWeb(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIcon(
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