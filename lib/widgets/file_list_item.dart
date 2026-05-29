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

  Future<void> _confirmarExclusaoArquivo() async {
    _focusNode.unfocus();
    final scheme = Theme.of(context).colorScheme;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover arquivo?'),
        content: const Text('Isso apagará o índice do arquivo e suas anotações no app.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Remover', style: TextStyle(color: scheme.error)),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    final fullPath = widget.item['fullPath']?.toString();
    if (fullPath == null || fullPath.isEmpty) return;

    final box = Hive.box('minha_biblioteca');
    final settingsBox = Hive.box('settings');

    await box.delete(fullPath);

    final annKey = 'item_ann_$fullPath';
    await settingsBox.delete(annKey);

    final doodleKey = 'doodle_$fullPath';
    await settingsBox.delete(doodleKey);
  }

  void _mostrarHierarquia() {
    final fullPath = widget.item['fullPath']?.toString() ?? '';
    if (fullPath.isEmpty) return;

    final box = Hive.box('minha_biblioteca');
    final List<Map<String, dynamic>> reversed = [];
    String? currentId = fullPath;

    while (currentId != null) {
      final raw = box.get(currentId);
      if (raw is! Map) break;
      final item = Map<String, dynamic>.from(raw);
      reversed.add(item);
      final pai = item['pai']?.toString();
      if (pai == null || pai == 'os_root') break;
      currentId = pai;
    }

    final chain = reversed.reversed.toList();

    final scheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hierarquia da pasta'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < chain.length; i++)
                Padding(
                  padding: EdgeInsets.only(left: i * 20.0),
                  child: Row(
                    children: [
                      Icon(
                        i < chain.length - 1
                            ? Icons.folder
                            : Icons.insert_drive_file,
                        size: 18,
                        color: i < chain.length - 1
                            ? scheme.primary
                            : scheme.onSurface,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          chain[i]['nome']?.toString() ?? '',
                          style: TextStyle(
                            fontWeight: i < chain.length - 1
                                ? FontWeight.normal
                                : FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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

    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box box, _) {
        final mostrarAnotacao = box.get('mostrarAnotacao', defaultValue: true);
        final mostrarEmoji = box.get('mostrarEmoji', defaultValue: true);
        final mostrarRepertorio = box.get('mostrarRepertorio', defaultValue: true);
        final mostrarLetra = box.get('mostrarLetra', defaultValue: true);
        final mostrarVideo = box.get('mostrarVideo', defaultValue: true);

        return ListTile(
          dense: true,
          title: GestureDetector(
            onTap: widget.onViewTap ??
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
            onLongPress: _mostrarHierarquia,
            child: Text(nome, overflow: TextOverflow.ellipsis),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (mostrarAnotacao)
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
              if (mostrarEmoji)
                _buildActionIcon(
                  Icons.emoji_emotions,
                  scheme.primary,
                  _showEmojiPicker,
                ),
              if (mostrarRepertorio && widget.showFavorite) ...[
                const SizedBox(width: 2),
                _buildActionIcon(
                  Icons.music_note,
                  scheme.tertiary,
                  () => _adicionarAoRepertorio(),
                ),
              ],
              if (mostrarLetra) ...[
                const SizedBox(width: 2),
                _buildActionIcon(
                  Icons.lyrics,
                  scheme.secondary,
                  widget.onLyricsTap ?? () => _buscarLetraWeb(),
                ),
              ],
              if (mostrarVideo) ...[
                const SizedBox(width: 2),
                _buildActionIcon(
                  Icons.play_circle_fill,
                  scheme.error,
                  widget.onVideoTap ?? () => _buscarVideoWeb(),
                ),
              ],
              const SizedBox(width: 2),
              IconButton(
                icon: Icon(Icons.delete_outline, color: scheme.error, size: 20),
                onPressed: _confirmarExclusaoArquivo,
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.symmetric(horizontal: 4),
              ),
            ],
          ),
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
