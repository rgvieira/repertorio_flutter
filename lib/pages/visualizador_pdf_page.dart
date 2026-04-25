import 'dart:io';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

import 'painter_overlay.dart'; // Doodle + DrawingCanvas

import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;

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
  final GlobalKey _pdfAreaKey = GlobalKey(); // área do viewer

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
  sfpdf.PdfDocument? _pdfDocument;

  bool _mostrarPainelFerramentas = true;

  @override
  void initState() {
    super.initState();
    _configPdfBox = Hive.box('config_pdf');
    _carregarUltimaPagina();
    _carregarDesenhosSalvos();
  }

  String _chavePdf(String path) => 'pdf_last_page:$path';

  void _carregarUltimaPagina() {
    final saved = _configPdfBox.get(_chavePdf(widget.filePath)) as int?;
    _ultimaPaginaSalva = saved;
  }

  void _salvarUltimaPagina(int page) {
    _configPdfBox.put(_chavePdf(widget.filePath), page);
  }

  void _carregarDesenhosSalvos() {
    final box = Hive.box('settings');
    final jsonSalvo = box.get('desenhos_${widget.filePath}');

    if (jsonSalvo != null) {
      final decoded = jsonDecode(jsonSalvo) as Map<String, dynamic>;
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
    final box = Hive.box('settings');
    final paraSalvar = _desenhosPorPagina.map((key, value) {
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

  /// TAP no PDF – navegação por borda e texto no meio
  Future<void> _handleTapOnPdf(PdfGestureDetails details) async {
    final renderBox =
        _pdfAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    if (size.width == 0 || size.height == 0) return;

    final pos = details.position;
    final x = pos.dx;

    // 1) Se estiver em modo edição + ferramenta TEXTO,
    //    o toque vale para texto em QUALQUER lugar da página (sem navegação)
    if (_modoEdicao && _ferramentaAtiva == 'text' && details.pageNumber > 0) {
      final texto = await _pedirTexto(context);
      if (texto == null || texto.trim().isEmpty) return;

      final xNorm = (x / size.width).clamp(0.0, 1.0);
      final yNorm = (pos.dy / size.height).clamp(0.0, 1.0);

      setState(() {
        _desenhosPorPagina.putIfAbsent(details.pageNumber, () => []).add(
              Doodle(
                [Offset(xNorm, yNorm)],
                _corAtiva,
                'text:${texto.trim()}',
              ),
            );
      });

      _salvarNoBanco();
      return;
    }

    // 2) Navegação por toque nas bordas
    //    Só quando NÃO estiver em modo edição (pra não brigar com desenho)
    if (!_modoEdicao) {
      final leftEdge = size.width * 0.2;
      final rightEdge = size.width * 0.8;

      if (x < leftEdge) {
        _pdfController.previousPage();
        return;
      }

      if (x > rightEdge) {
        _pdfController.nextPage();
        return;
      }
    }

    // 3) Fora destas condições, não faz nada (tap normal)
  }

  /// IMPRESSÃO COM ANOTAÇÕES
  Future<void> _imprimirComAnotacoes() async {
    try {
      final pdfOriginal = await File(widget.filePath).readAsBytes();
      final pdfOutput = pw.Document();

      int pageIndex = 1;
      await for (final page in Printing.raster(pdfOriginal)) {
        final currentPage = pageIndex;

        pdfOutput.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              page.width.toDouble(),
              page.height.toDouble(),
              marginAll: 0,
            ),
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  pw.Image(
                    pw.RawImage(
                      bytes: page.pixels,
                      width: page.width,
                      height: page.height,
                    ),
                    fit: pw.BoxFit.fill,
                  ),
                  if (_desenhosPorPagina.containsKey(currentPage)) ...[
                    _buildPageAnnotations(
                      currentPage,
                      page.width,
                      page.height,
                    ),
                    ..._buildTextAnnotations(
                      currentPage,
                      page.width,
                      page.height,
                    ),
                  ],
                ],
              );
            },
          ),
        );

        pageIndex++;
      }

      await Printing.layoutPdf(
        onLayout: (_) => pdfOutput.save(),
        name: widget.title,
      );
    } catch (e) {
      debugPrint("Erro ao imprimir: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao imprimir: $e')),
        );
      }
    }
  }

  /// DESENHOS (caneta, círculo, etc.) NA IMPRESSÃO
  pw.Widget _buildPageAnnotations(int page, int width, int height) {
    return pw.Positioned.fill(
      child: pw.CustomPaint(
        size: PdfPoint(width.toDouble(), height.toDouble()),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final pageWidth = size.x;
          final pageHeight = size.y;

          for (final doodle in _desenhosPorPagina[page] ?? []) {
            if (doodle.pontos.isEmpty ||
                doodle.ferramenta.startsWith('text:')) {
              continue;
            }

            final opacity = doodle.ferramenta == 'highlight' ? 0.08 : 0.30;
            canvas.setStrokeColor(
              PdfColor.fromInt(doodle.cor.value).withAlpha(opacity),
            );
            canvas.setLineWidth(doodle.ferramenta == 'highlight' ? 15 : 2);
            canvas.setLineCap(PdfLineCap.round);

            final path = doodle.pontos.map((p) {
              final dx = p.dx * pageWidth;
              final dy = p.dy * pageHeight;
              return Offset(dx, dy);
            }).toList();

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
              case 'arrow':
                if (path.length >= 2) {
                  final first = path.first;
                  final last = path.last;
                  canvas.moveTo(first.dx, first.dy);
                  canvas.lineTo(last.dx, last.dy);
                  canvas.strokePath();

                  if (doodle.ferramenta == 'arrow') {
                    final angle =
                        math.atan2(last.dy - first.dy, last.dx - first.dx);
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
            }
          }
        },
      ),
    );
  }

  /// TEXTOS NA IMPRESSÃO
  List<pw.Widget> _buildTextAnnotations(int page, int width, int height) {
    return _desenhosPorPagina[page]!
        .where((d) => d.ferramenta.startsWith('text:'))
        .map((doodle) {
      final p = doodle.pontos.first;
      final pdfX = p.dx * width;
      final pdfY = p.dy * height;

      const fontSize = 18.0;

      return pw.Positioned(
        left: pdfX,
        top: pdfY - fontSize * 0.7,
        child: pw.Text(
          doodle.ferramenta.substring(5),
          style: pw.TextStyle(
            color: PdfColor.fromInt(doodle.cor.value),
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildToolButton(String tool, IconData icon, String tooltip) {
    final isActive = _ferramentaAtiva == tool;
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
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box box, _) {
        final modoNoite = box.get('modoNoite', defaultValue: false);
        final horizontal = box.get('horizontal', defaultValue: false);

        return Scaffold(
          backgroundColor: modoNoite ? Colors.black : const Color(0xFF525659),
          appBar: AppBar(
            backgroundColor: const Color(0xFF186879),
            foregroundColor: Colors.white,
            title: Text(
              widget.title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                  icon:
                      const Icon(Icons.arrow_forward_ios, color: Colors.white),
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
                        0,
                      ])
                    : const ColorFilter.mode(
                        Colors.transparent,
                        BlendMode.multiply,
                      ),
                child: SfPdfViewer.file(
                  File(widget.filePath),
                  key: _pdfAreaKey,
                  controller: _pdfController,
                  scrollDirection: horizontal
                      ? PdfScrollDirection.horizontal
                      : PdfScrollDirection.vertical,
                  pageLayoutMode: PdfPageLayoutMode.single, // SEMPRE UMA PÁGINA
                  onDocumentLoaded: (details) {
                    setState(() {
                      _totalPaginas = details.document.pages.count;
                      _pdfDocument = details.document;
                      if (_ultimaPaginaSalva != null &&
                          _ultimaPaginaSalva! >= 1 &&
                          _ultimaPaginaSalva! <= _totalPaginas) {
                        _pdfController.jumpToPage(_ultimaPaginaSalva!);
                        _paginaAtual = _ultimaPaginaSalva!;
                      } else {
                        _paginaAtual = 1;
                      }
                    });
                  },
                  onPageChanged: (details) {
                    setState(() => _paginaAtual = details.newPageNumber);
                    _salvarUltimaPagina(details.newPageNumber);
                  },
                  onTap: _handleTapOnPdf,
                ),
              ),

              // OVERLAY DE DESENHO
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    _canvasWidth = constraints.maxWidth;
                    _canvasHeight = constraints.maxHeight;
                    return IgnorePointer(
                      ignoring: _modoEdicao && _ferramentaAtiva == 'text',
                      child: DrawingCanvas(
                        ferramenta: _ferramentaAtiva,
                        cor: _corAtiva,
                        podeDesenhar: _modoEdicao,
                        historico: _desenhosPorPagina[_paginaAtual] ?? [],
                        aoFinalizar: (novoDoodle) {
                          setState(() {
                            if (_ferramentaAtiva == 'eraser') {
                              _desenhosPorPagina[_paginaAtual]?.removeWhere(
                                (d) => d.pontos.any(
                                  (p) =>
                                      (p - novoDoodle.pontos.first).distance <
                                      30,
                                ),
                              );
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

              // PAINEL DE FERRAMENTAS RECOLHÍVEL
              if (_modoEdicao)
                Positioned(
                  right: 12,
                  top: 80,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        mini: true,
                        backgroundColor: const Color(0xFF186879),
                        onPressed: () {
                          setState(() {
                            _mostrarPainelFerramentas =
                                !_mostrarPainelFerramentas;
                          });
                        },
                        child: Icon(
                          _mostrarPainelFerramentas ? Icons.close : Icons.brush,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_mostrarPainelFerramentas)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildToolButton(
                                    'pen', Icons.gesture, 'Caneta'),
                                _buildToolButton('highlight', Icons.highlight,
                                    'Marca-texto'),
                                _buildToolButton('eraser',
                                    Icons.auto_fix_normal, 'Borracha'),
                                _buildToolButton(
                                    'line', Icons.line_style, 'Linha'),
                                _buildToolButton(
                                    'arrow', Icons.trending_flat, 'Seta'),
                                _buildToolButton(
                                    'circle', Icons.circle_outlined, 'Círculo'),
                                _buildToolButton(
                                    'text', Icons.text_fields, 'Texto'),
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
                                        _desenhosPorPagina[_paginaAtual]
                                            ?.clear());
                                    _salvarNoBanco();
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
