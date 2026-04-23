import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'painter_overlay.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';

class VisualizadorPdfPage extends StatefulWidget {
  final String filePath;
  final String title;

  const VisualizadorPdfPage({
    super.key,
    required this.filePath,
    required this.title,
  });

  @override
  State<VisualizadorPdfPage> createState() => _VisualizadorPdfPageState();
}

class _VisualizadorPdfPageState extends State<VisualizadorPdfPage> {
  final PdfViewerController _pdfController = PdfViewerController();

  bool _modoEdicao = false;
  String _ferramentaAtiva = 'pen';
  Color _corAtiva = Colors.red;

  int _paginaAtual = 1;
  int _totalPaginas = 0;
  Map<int, List<Doodle>> _desenhosPorPagina = {};

  late final Box _configPdfBox;
  int? _ultimaPaginaSalva;

  double _canvasWidth = 1;
  double _canvasHeight = 1;

  sfpdf.PdfDocument? _pdfDocument; // documento real para saber tamanho da página

  @override
  void initState() {
    super.initState();
    _configPdfBox = Hive.box('config_pdf');
    _carregarUltimaPagina();
    _carregarDesenhosSalvos();
  }

  void _carregarUltimaPagina() {
    final key = _chavePdf(widget.filePath);
    final saved = _configPdfBox.get(key) as int?;
    _ultimaPaginaSalva = saved;
  }

  void _salvarUltimaPagina(int page) {
    final key = _chavePdf(widget.filePath);
    _configPdfBox.put(key, page);
  }

  String _chavePdf(String path) => 'pdf_last_page:$path';

  void _carregarDesenhosSalvos() {
    var box = Hive.box('settings');
    String? jsonSalvo = box.get('desenhos_${widget.filePath}');

    if (jsonSalvo != null) {
      Map<String, dynamic> decoded = jsonDecode(jsonSalvo);
      setState(() {
        _desenhosPorPagina = decoded.map((key, value) {
          return MapEntry(
            int.parse(key),
            (value as List).map((d) => Doodle.fromMap(d)).toList(),
          );
        });
      });
    }
  }

  void _salvarNoBanco() {
    var box = Hive.box('settings');
    Map<String, dynamic> paraSalvar =
        _desenhosPorPagina.map((key, value) {
      return MapEntry(key.toString(), value.map((d) => d.toMap()).toList());
    });
    box.put('desenhos_${widget.filePath}', jsonEncode(paraSalvar));
  }

  Future<String?> _pedirTexto(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anotação na Partitura'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Digite aqui..."),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
Future<void> _handleTapOnPdf(PdfGestureDetails details) async {
  if (!_modoEdicao || _ferramentaAtiva != 'text') return;
  if (details.pageNumber <= 0) return;

  final texto = await _pedirTexto(context);
  if (texto == null || texto.trim().isEmpty) return;

  // 1) posição absoluta do toque na tela
  final Offset tapPos = details.position;

  // 2) pega o RenderBox do overlay inteiro (a área onde o DrawingCanvas desenha)
  final RenderBox? box = context.findRenderObject() as RenderBox?;
  if (box == null) return;
  final Size overlaySize = box.size;
  if (overlaySize.width == 0 || overlaySize.height == 0) return;

  // 3) normaliza em relação ao overlay (0..1)
  double xNorm = tapPos.dx / overlaySize.width;
  double yNorm = tapPos.dy / overlaySize.height;

  // 4) garante 0..1 para não sair do canvas
  xNorm = xNorm.clamp(0.0, 1.0);
  yNorm = yNorm.clamp(0.0, 1.0);

  final doodle = Doodle(
    [Offset(xNorm, yNorm)],
    _corAtiva,
    'text:${texto.trim()}',
  );

  setState(() {
    _desenhosPorPagina
        .putIfAbsent(details.pageNumber, () => [])
        .add(doodle);
  });
  _salvarNoBanco();
}


  Future<void> _imprimirComAnotacoes() async {
    final pdfOriginal = await File(widget.filePath).readAsBytes();
    final pw.Document pdfOutput = pw.Document();

    try {
      int pageIndex = 1;
      await for (var page in Printing.raster(pdfOriginal)) {
        final int currentPage = pageIndex;

        pdfOutput.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              page.width.toDouble(),
              page.height.toDouble(),
              marginAll: 0,
            ),
            build: (pw.Context pdfCtx) {
              return pw.Stack(
                children: [
                  pw.Image(
                    pw.RawImage(
                      bytes: page.pixels,
                      width: page.width,
                      height: page.height,
                    ),
                  ),

                  if (_desenhosPorPagina.containsKey(currentPage))
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        size: PdfPoint(
                          page.width.toDouble(),
                          page.height.toDouble(),
                        ),
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          final double pdfPageWidth = size.x;
                          final double pdfPageHeight = size.y;

                          for (var doodle
                              in _desenhosPorPagina[currentPage] ?? []) {
                            if (doodle.pontos.isEmpty) continue;
                            if (doodle.ferramenta.startsWith('text:')) {
                              continue;
                            }

                            final double opacity =
                                (doodle.ferramenta == 'highlight')
                                    ? 0.08
                                    : 0.30;

                            canvas.setStrokeColor(
                              PdfColor.fromInt(doodle.cor.value)
                                  .withAlpha(opacity),
                            );
                            canvas.setLineWidth(
                              doodle.ferramenta == 'highlight' ? 15 : 2,
                            );
                            canvas.setLineCap(PdfLineCap.round);

                            final path = <Offset>[];

for (var pNorm in doodle.pontos) {
  final double pdfX = pNorm.dx * pdfPageWidth;
  // inverte o Y porque o PDF conta de baixo pra cima
  final double pdfY = (1.0 - pNorm.dy) * pdfPageHeight;
  path.add(Offset(pdfX, pdfY));
}

                            if (path.isEmpty) continue;

                            switch (doodle.ferramenta) {
                              case 'circle':
                                if (path.length >= 2) {
                                  final p1 = path.first;
                                  final p2 = path.last;
                                  final cx = (p1.dx + p2.dx) / 2;
                                  final cy = (p1.dy + p2.dy) / 2;
                                  final rx =
                                      (p2.dx - p1.dx).abs() / 2;
                                  final ry =
                                      (p2.dy - p1.dy).abs() / 2;

                                  canvas.drawEllipse(cx, cy, rx, ry);
                                  canvas.strokePath();
                                }
                                break;

                              case 'line':
                                if (path.length >= 2) {
                                  final first = path.first;
                                  final last = path.last;

                                  canvas.moveTo(first.dx, first.dy);
                                  canvas.lineTo(last.dx, last.dy);
                                  canvas.strokePath();
                                }
                                break;

                              case 'arrow':
                                if (path.length >= 2) {
                                  final first = path.first;
                                  final last = path.last;

                                  final angle = math.atan2(
                                    last.dy - first.dy,
                                    last.dx - first.dx,
                                  );

                                  canvas.moveTo(first.dx, first.dy);
                                  canvas.lineTo(last.dx, last.dy);
                                  canvas.strokePath();

                                  canvas.moveTo(
                                    last.dx -
                                        15 * math.cos(angle - 0.5),
                                    last.dy -
                                        15 * math.sin(angle - 0.5),
                                  );
                                  canvas.lineTo(last.dx, last.dy);
                                  canvas.lineTo(
                                    last.dx -
                                        15 * math.cos(angle + 0.5),
                                    last.dy -
                                        15 * math.sin(angle + 0.5),
                                  );
                                  canvas.strokePath();
                                }
                                break;

                              case 'pen':
                              case 'highlight':
                                canvas.moveTo(path.first.dx, path.first.dy);
                                for (int i = 1; i < path.length; i++) {
                                  canvas.lineTo(path[i].dx, path[i].dy);
                                }
                                canvas.strokePath();
                                break;

                              default:
                                break;
                            }
                          }
                        },
                      ),
                    ),

                  if (_desenhosPorPagina.containsKey(currentPage))
                    ..._desenhosPorPagina[currentPage]!
                        .where(
                          (d) => d.ferramenta.startsWith('text:'),
                        )
                        .map((doodle) {
final pNorm = doodle.pontos.first;

final double pdfX = pNorm.dx * page.width;
// inverte o Y
final double pdfY = (1.0 - pNorm.dy) * page.height;

const double fontSize = 18.0;
final double textOffsetY = fontSize * 0.7;

return pw.Positioned(
  left: pdfX,
  top: pdfY - textOffsetY,
  child: pw.Text(
    doodle.ferramenta.substring(5),
    style: pw.TextStyle(
      color: PdfColor.fromInt(doodle.cor.value),
      fontSize: fontSize,
      fontWeight: pw.FontWeight.bold,
    ),
  ),
);
                    }).toList(),
                ],
              );
            },
          ),
        );
        pageIndex++;
      }

      await Printing.layoutPdf(
        onLayout: (format) async => pdfOutput.save(),
        name: widget.title,
      );
    } catch (e) {
      debugPrint("Erro ao imprimir com anotações: $e");
    }
  }

  Widget _buildToolButton(String tool, IconData icon, String tooltip) {
    final bool isActive = _ferramentaAtiva == tool;
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? Colors.orange : const Color(0xFF186879),
        size: 28,
      ),
      onPressed: () => setState(() => _ferramentaAtiva = tool),
      tooltip: tooltip,
    );
  }

  void _escolherCor() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Escolha uma cor'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: _corAtiva,
            onColorChanged: (color) {
              setState(() => _corAtiva = color);
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
//Para ser retirado depois 
    _desenhosPorPagina.putIfAbsent(_paginaAtual, () => []);
  if (_desenhosPorPagina[_paginaAtual]!
      .where((d) => d.ferramenta.startsWith('text:DEBUG'))
      .isEmpty) {
    _desenhosPorPagina[_paginaAtual]!.add(
      Doodle(
        [const Offset(0.5, 0.5)], // meio da tela
        Colors.blue,
        'text:DEBUG',
      ),
    );
  }
    var settingsBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box b, _) {
        bool modoNoite = b.get('modoNoite', defaultValue: false);
        bool horizontal = b.get('horizontal', defaultValue: false);

        return Scaffold(
          backgroundColor:
              modoNoite ? Colors.black : const Color(0xFF525659),
          appBar: AppBar(
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF186879),
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: const Icon(Icons.print, color: Colors.white),
                onPressed: _imprimirComAnotacoes,
              ),
              IconButton(
                icon: Icon(
                  _modoEdicao ? Icons.brush : Icons.edit_off,
                  color: _modoEdicao ? Colors.orange : Colors.white,
                ),
                onPressed: () =>
                    setState(() => _modoEdicao = !_modoEdicao),
              ),
            ],
          ),
          bottomNavigationBar: Container(
            height: 60,
            color: const Color(0xFF186879),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon:
                      const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => _pdfController.previousPage(),
                ),
                Text(
                  "Pág: $_paginaAtual / $_totalPaginas",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white,
                  ),
                  onPressed: () => _pdfController.nextPage(),
                ),
              ],
            ),
          ),
          body: Stack(
            children: [
              ColorFiltered(
                colorFilter: modoNoite
                    ? const ColorFilter.matrix([
                        -1, 0, 0, 0, 255,
                        0, -1, 0, 0, 255,
                        0, 0, -1, 0, 255,
                        0, 0, 0, 1, 0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: SfPdfViewer.file(
  File(widget.filePath),
  controller: _pdfController,
  scrollDirection: horizontal
      ? PdfScrollDirection.horizontal
      : PdfScrollDirection.vertical,
  pageLayoutMode: horizontal
      ? PdfPageLayoutMode.single
      : PdfPageLayoutMode.continuous,
  onDocumentLoaded: (PdfDocumentLoadedDetails details) {
    setState(() {
      _totalPaginas = details.document.pages.count;
      _pdfDocument = details.document;
    });

    if (_ultimaPaginaSalva != null &&
        _ultimaPaginaSalva! >= 1 &&
        _ultimaPaginaSalva! <= _totalPaginas) {
      _pdfController.jumpToPage(_ultimaPaginaSalva!);
      _paginaAtual = _ultimaPaginaSalva!;
    } else {
      _paginaAtual = 1;
    }
  },
  onPageChanged: (PdfPageChangedDetails details) {
    setState(() {
      _paginaAtual = details.newPageNumber;
    });
    _salvarUltimaPagina(details.newPageNumber);
  },
  onTap: _handleTapOnPdf,
),
              ),
 Positioned.fill(
  child: LayoutBuilder(
    builder: (context, constraints) {
      _canvasWidth = constraints.maxWidth;
      _canvasHeight = constraints.maxHeight;

      return IgnorePointer(
        // QUANDO for texto, o overlay NÃO recebe toque.
        ignoring: _modoEdicao && _ferramentaAtiva == 'text',
        child: DrawingCanvas(
          ferramenta: _ferramentaAtiva,
          cor: _corAtiva,
          podeDesenhar: _modoEdicao,
          historico: _desenhosPorPagina[_paginaAtual] ?? [],
          aoFinalizar: (novoDoodle) {
            setState(() {
              if (_ferramentaAtiva == 'eraser') {
                _desenhosPorPagina[_paginaAtual]
                    ?.removeWhere((d) => d.pontos.any(
                          (p) =>
                              (p - novoDoodle.pontos.first).distance < 30,
                        ));
              } else {
                _desenhosPorPagina
                    .putIfAbsent(_paginaAtual, () => [])
                    .add(novoDoodle);
              }
            });
            _salvarNoBanco();
          },
        ),
      );
    },
  ),
),
              if (_modoEdicao)
                Positioned(
                  right: 12,
                  top: 80,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildToolButton(
                              'pen', Icons.gesture, 'Caneta'),
                          _buildToolButton('highlight',
                              Icons.highlight, 'Marca-texto'),
                          _buildToolButton('eraser',
                              Icons.auto_fix_normal, 'Borracha'),
                          _buildToolButton(
                              'line', Icons.line_style, 'Linha'),
                          _buildToolButton('arrow',
                              Icons.trending_flat, 'Seta'),
                          _buildToolButton('circle',
                              Icons.circle_outlined, 'Círculo'),
                          _buildToolButton(
                              'text', Icons.text_fields, 'Texto'),
                          const Divider(),
                          IconButton(
                            icon:
                                Icon(Icons.circle, color: _corAtiva),
                            onPressed: _escolherCor,
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_sweep,
                              color: Colors.red,
                            ),
                            onPressed: () {
                              setState(() =>
                                  _desenhosPorPagina[_paginaAtual]
                                      ?.clear());
                              _salvarNoBanco();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}