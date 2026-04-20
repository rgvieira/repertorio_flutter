import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'painter_overlay.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'dart:math' as math;

class VisualizadorPdfPage extends StatefulWidget {
  final String filePath;
  final String title;

  const VisualizadorPdfPage(
      {super.key, required this.filePath, required this.title});

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

  @override
  void initState() {
    super.initState();
    _carregarDesenhosSalvos();
  }

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
    Map<String, dynamic> paraSalvar = _desenhosPorPagina.map((key, value) {
      return MapEntry(key.toString(), value.map((d) => d.toMap()).toList());
    });
    box.put('desenhos_${widget.filePath}', jsonEncode(paraSalvar));
  }

  Future<void> _imprimirComAnotacoes() async {
    final pdfOriginal = await File(widget.filePath).readAsBytes();
    final pw.Document pdfOutput = pw.Document();

    final BuildContext flutterContext = context;
    final Size screenSize = MediaQuery.of(flutterContext).size;

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
                  // Imagem da página original
                  pw.Image(
                    pw.RawImage(
                      bytes: page.pixels,
                      width: page.width,
                      height: page.height,
                    ),
                  ),

                  // Desenho vetor: caneta, marca‑texto, linha, seta, círculo
                  if (_desenhosPorPagina.containsKey(currentPage))
                    pw.Positioned.fill(
                      child: pw.CustomPaint(
                        size: PdfPoint(
                            page.width.toDouble(), page.height.toDouble()),
                        painter: (PdfGraphics canvas, PdfPoint size) {
                          final double pdfPageWidth = size.x;
                          final double pdfPageHeight = size.y;

                          for (var doodle
                              in _desenhosPorPagina[currentPage] ?? []) {
                            if (doodle.pontos.isEmpty) continue;

                            final double opacity =
                                (doodle.ferramenta == 'highlight') ? 0.3 : 1.0;

                            canvas.setStrokeColor(
                              PdfColor.fromInt(doodle.cor.value)
                                  .withAlpha(opacity),
                            );
                            canvas.setLineWidth(
                              doodle.ferramenta == 'highlight' ? 15 : 2,
                            );
                            canvas.setLineCap(PdfLineCap.round);

                            final path = <Offset>[];
                            for (var pontoTela in doodle.pontos) {
                              double pdfX = pontoTela.dx *
                                  (pdfPageWidth / screenSize.width);
                              double pdfY = pontoTela.dy *
                                  (pdfPageHeight / screenSize.height);
                              pdfY = pdfPageHeight - pdfY;
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
                                  final rx = (p2.dx - p1.dx).abs() / 2;
                                  final ry = (p2.dy - p1.dy).abs() / 2;

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
                                    last.dx - 15 * math.cos(angle - 0.5),
                                    last.dy - 15 * math.sin(angle - 0.5),
                                  );
                                  canvas.lineTo(last.dx, last.dy);
                                  canvas.lineTo(
                                    last.dx - 15 * math.cos(angle + 0.5),
                                    last.dy - 15 * math.sin(angle + 0.5),
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

                  // TEXTO: usa a mesma escala de desenho, sem distorção
                  if (_desenhosPorPagina.containsKey(currentPage))
                    ..._desenhosPorPagina[currentPage]!
                        .where((d) => d.ferramenta.startsWith('text:'))
                        .map((doodle) {
                      final pt = doodle.pontos.first;
                      // mesmo mapeamento de coordenada do CustomPaint
                      final double pdfX =
                          pt.dx * (page.width / screenSize.width);
                      final double pdfY =
                          pt.dy * (page.height / screenSize.height);

                      return pw.Positioned(
                        left: pdfX,
                        top: pdfY - 20,
                        child: pw.Text(
                          doodle.ferramenta.substring(5),
                          style: pw.TextStyle(
                            color: PdfColor.fromInt(doodle.cor.value),
                            fontSize: 12,
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
    var settingsBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box b, _) {
        bool modoNoite = b.get('modoNoite', defaultValue: false);
        bool horizontal = b.get('horizontal', defaultValue: false);

        return Scaffold(
          backgroundColor: modoNoite ? Colors.black : const Color(0xFF525659),
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: const Color(0xFF186879),
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
                onPressed: () => setState(() => _modoEdicao = !_modoEdicao),
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
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
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
                        -1,
                        0,
                        0,
                        0,
                        255,
                        0,
                        -1,
                        0,
                        0,
                        255,
                        0,
                        0,
                        -1,
                        0,
                        255,
                        0,
                        0,
                        0,
                        1,
                        0
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
                  onDocumentLoaded: (details) => setState(
                    () => _totalPaginas = details.document.pages.count,
                  ),
                  onPageChanged: (details) => setState(
                    () => _paginaAtual = details.newPageNumber,
                  ),
                ),
              ),
              Positioned.fill(
                child: DrawingCanvas(
                  ferramenta: _ferramentaAtiva,
                  cor: _corAtiva,
                  podeDesenhar: _modoEdicao,
                  historico: _desenhosPorPagina[_paginaAtual] ?? [],
                  aoFinalizar: (novoDoodle) {
                    setState(() {
                      if (_ferramentaAtiva == 'eraser') {
                        _desenhosPorPagina[_paginaAtual]?.removeWhere((d) =>
                            d.pontos.any((p) =>
                                (p - novoDoodle.pontos.first).distance < 30));
                      } else {
                        _desenhosPorPagina
                            .putIfAbsent(_paginaAtual, () => [])
                            .add(novoDoodle);
                      }
                    });
                    _salvarNoBanco();
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
                          _buildToolButton('pen', Icons.gesture, 'Caneta'),
                          _buildToolButton(
                              'highlight', Icons.highlight, 'Marca-texto'),
                          _buildToolButton(
                              'eraser', Icons.auto_fix_normal, 'Borracha'),
                          _buildToolButton('line', Icons.line_style, 'Linha'),
                          _buildToolButton(
                              'arrow', Icons.trending_flat, 'Seta'),
                          _buildToolButton(
                              'circle', Icons.circle_outlined, 'Círculo'),
                          _buildToolButton('text', Icons.text_fields, 'Texto'),
                          const Divider(),
                          IconButton(
                            icon: Icon(Icons.circle, color: _corAtiva),
                            onPressed: _escolherCor,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep,
                                color: Colors.red),
                            onPressed: () {
                              setState(() =>
                                  _desenhosPorPagina[_paginaAtual]?.clear());
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
