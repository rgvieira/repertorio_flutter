import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:repertorio_flutter/pages/repertorio_page.dart'
    show RepertorioPage;
import 'package:repertorio_flutter/pages/visualizador_pdf_page.dart';
import 'package:repertorio_flutter/widgets/emoji_picker.dart';
import 'package:url_launcher/url_launcher.dart';

class FileListItem extends StatefulWidget {
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

  @override
  State<FileListItem> createState() => _FileListItemState();
}

class _FileListItemState extends State<FileListItem> {
  late final TextEditingController _annotationCtrl;
  late final FocusNode _focusNode;
  late final String _annotationKey;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _annotationKey = 'item_ann_${widget.item['fullPath']}';
    final saved = Hive.box('settings').get(_annotationKey, defaultValue: '') as String;
    _annotationCtrl = TextEditingController(text: saved);
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        _saveAnnotation();
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _annotationCtrl.dispose();
    super.dispose();
  }

  void _saveAnnotation() {
    Hive.box('settings').put(_annotationKey, _annotationCtrl.text);
  }

  void _showEmojiPicker() {
    _focusNode.unfocus();
    showModalBottomSheet(
      context: context,
      builder: (_) => EmojiPickerSheet(
        onSelected: (emoji) {
          final text = _annotationCtrl.text;
          final sel = _annotationCtrl.selection;
          final pos = sel.isValid ? sel.baseOffset : text.length;
          final clamped = pos.clamp(0, text.length);
          final newText = text.substring(0, clamped) + emoji + text.substring(clamped);
          _annotationCtrl.text = newText;
          _annotationCtrl.selection = TextSelection.collapsed(offset: clamped + emoji.length);
          _saveAnnotation();
        },
      ),
    );
  }

  void _buscarLetraWeb() {
    _focusNode.unfocus();
    final nomeLimpo = p.basenameWithoutExtension(widget.item['nome'].toString());
    final String query = Uri.encodeComponent('letra da música $nomeLimpo');
    final Uri url = Uri.parse('https://www.google.com/search?q=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  void _buscarVideoWeb() {
    _focusNode.unfocus();
    final nomeLimpo = p.basenameWithoutExtension(widget.item['nome'].toString());
    final String query = Uri.encodeComponent(nomeLimpo);
    final Uri url =
        Uri.parse('https://www.youtube.com/results?search_query=$query');
    launchUrl(url, mode: LaunchMode.externalApplication);
  }

  Future<void> _adicionarAoRepertorio() async {
    _focusNode.unfocus();
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RepertorioPage(
          fileToAdd: widget.item,
        ),
      ),
    );
    _focusNode.unfocus();
  }

  IconData _getIcon() {
    final String extensao = (widget.item['extensao'] ?? '').toString().toLowerCase();
    final String tipo = widget.item['tipo']?.toString() ?? '';

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
    final bool isDir = widget.item['tipo'] == 'dir';
    final String nome = p.basenameWithoutExtension(widget.item['nome'].toString());
    final scheme = Theme.of(context).colorScheme;

    if (isDir) {
      return ListTile(
        dense: true,
        leading: Icon(_getIcon(), color: scheme.primary, size: 20),
        title: Text(nome, style: const TextStyle(fontWeight: FontWeight.bold)),
      );
    }

    return ListTile(
      dense: true,
      leading: Icon(_getIcon(), color: scheme.primary, size: 20),
      title: Text(nome, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 80,
            child: TextField(
              focusNode: _focusNode,
              controller: _annotationCtrl,
              decoration: InputDecoration(
                hintText: _annotationCtrl.text.isEmpty ? '+' : null,
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: scheme.outline.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: scheme.outline.withAlpha(60)),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withAlpha(80),
                contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              ),
              style: TextStyle(fontSize: 13, color: scheme.onSurface),
              textAlign: TextAlign.center,
              maxLines: 1,
            ),
          ),
          const SizedBox(width: 2),
          InkWell(
            onTap: _showEmojiPicker,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withAlpha(100),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.emoji_emotions, size: 18, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 2),
          if (widget.showFavorite)
            _buildActionIcon(
              Icons.music_note,
              scheme.tertiary,
              () => _adicionarAoRepertorio(),
            ),
          _buildActionIcon(
            Icons.visibility,
            scheme.primary,
            widget.onViewTap ??
                () {
                  final path = widget.item['fullPath']?.toString();
                  if (path == null || path.isEmpty) return;
                  _focusNode.unfocus();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VisualizadorPdfPage(
                        filePath: path,
                        title: nome,
                      ),
                    ),
                  );
                },
          ),
          _buildActionIcon(
            Icons.lyrics,
            scheme.secondary,
            widget.onLyricsTap ?? () => _buscarLetraWeb(),
          ),
          _buildActionIcon(
            Icons.play_circle_fill,
            scheme.error,
            widget.onVideoTap ?? () => _buscarVideoWeb(),
          ),
        ],
      ),
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
