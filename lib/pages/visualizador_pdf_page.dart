import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart' as sfpdf;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'painter_overlay.dart'; // Doodle + DrawingCanvas

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

  /// TAP no PDF – navegação por borda e texto
  Future<void> _handleTapOnPdf(PdfGestureDetails details) async {
    final renderBox =
        _pdfAreaKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final localPos = details.position;
    final viewSize = renderBox.size;
    if (viewSize.width == 0 || viewSize.height == 0) return;

    // 1) Descobre o tamanho da página PDF atual
    final page = _pdfDocument?.pages[details.pageNumber - 1];
    if (page == null) return;

    final pdfW = page.size.width;
    final pdfH = page.size.height;
    final pdfAspect = pdfW / pdfH;

    final viewW = viewSize.width;
    final viewH = viewSize.height;
    final viewAspect = viewW / viewH;

    // 2) Calcula a área em que o PDF é desenhado dentro do viewer (fit)
    double drawW, drawH;
    if (pdfAspect > viewAspect) {
      // PDF mais "largo" que a área: limita pela largura
      drawW = viewW;
      drawH = viewW / pdfAspect;
    } else {
      // PDF mais "alto": limita pela altura
      drawH = viewH;
      drawW = viewH * pdfAspect;
    }

    final offsetX = (viewW - drawW) / 2;
    final offsetY = (viewH - drawH) / 2;

    // 3) Converte o toque para coordenadas dentro dessa área (clamp pra dentro)
    final relX = (localPos.dx - offsetX).clamp(0, drawW);
    final relY = (localPos.dy - offsetY).clamp(0, drawH);

    final xNorm = (relX / drawW).clamp(0.0, 1.0);
    final yNorm = (relY / drawH).clamp(0.0, 1.0);

    // 4) Modo edição + TEXTO → insere texto na posição normalizada
    if (_modoEdicao && _ferramentaAtiva == 'text' && details.pageNumber > 0) {
      final texto = await _pedirTexto(context);
      if (texto == null || texto.trim().isEmpty) return;

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

    // 5) Navegação por toque nas bordas – só fora do modo edição
    if (!_modoEdicao) {
      const double edgeThreshold = 0.10; // 10% de cada lado

      if (xNorm < edgeThreshold) {
        _pdfController.previousPage();
        return;
      }

      if (xNorm > 1.0 - edgeThreshold) {
        _pdfController.nextPage();
        return;
      }
    }

    // 6) Caso contrário, não faz nada especial
  }

  Future<void> _imprimirComAnotacoes() async {
    try {
      final originalBytes = await File(widget.filePath).readAsBytes();
      final pw.Document pdfOutput = pw.Document();

      final pages = await Printing.raster(
        originalBytes,
        dpi: 144,
      ).toList();

      const PdfPageFormat targetFormat = PdfPageFormat.a4;

      for (int i = 0; i < pages.length; i++) {
        final rasterPage = pages[i];
        final currentPage = i + 1;

        final double srcWidth = rasterPage.width.toDouble();
        final double srcHeight = rasterPage.height.toDouble();
        final double srcAspect = srcWidth / srcHeight;

        final double dstWidth = targetFormat.width;
        final double dstHeight = targetFormat.height;
        final double dstAspect = dstWidth / dstHeight;

        double drawWidth;
        double drawHeight;
        if (srcAspect > dstAspect) {
          drawWidth = dstWidth;
          drawHeight = dstWidth / srcAspect;
        } else {
          drawHeight = dstHeight;
          drawWidth = dstHeight * srcAspect;
        }

        final double offsetX = (dstWidth - drawWidth) / 2;
        final double offsetY = (dstHeight - drawHeight) / 2;

        pdfOutput.addPage(
          pw.Page(
            pageFormat: targetFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Imagem do PDF original
                  pw.Positioned(
                    left: offsetX,
                    top: offsetY,
                    child: pw.SizedBox(
                      width: drawWidth,
                      height: drawHeight,
                      child: pw.Image(
                        pw.RawImage(
                          bytes: rasterPage.pixels,
                          width: rasterPage.width,
                          height: rasterPage.height,
                        ),
                        fit: pw.BoxFit.fill,
                      ),
                    ),
                  ),

                  // Desenhos
                  if (_desenhosPorPagina.containsKey(currentPage))
                    pw.Positioned(
                      left: offsetX,
                      top: offsetY,
                      child: pw.SizedBox(
                        width: drawWidth,
                        height: drawHeight,
                        child: _buildPageAnnotationsScaled(
                          currentPage,
                          drawWidth,
                          drawHeight,
                        ),
                      ),
                    ),

                  // Textos (sobrepostos aos desenhos)
                  if (_desenhosPorPagina.containsKey(currentPage))
                    pw.Positioned(
                      left: offsetX,
                      top: offsetY,
                      child: pw.SizedBox(
                        width: drawWidth,
                        height: drawHeight,
                        child: pw.Stack(
                          children: _buildTextAnnotationsScaled(
                            currentPage,
                            drawWidth,
                            drawHeight,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
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

  pw.Widget _buildPageAnnotationsScaled(
    int page,
    double drawWidth,
    double drawHeight,
  ) {
    final doodles = _desenhosPorPagina[page] ?? [];

    return pw.Positioned.fill(
      child: pw.CustomPaint(
        size: PdfPoint(drawWidth, drawHeight),
        painter: (PdfGraphics canvas, PdfPoint size) {
          final pageWidth = size.x;
          final pageHeight = size.y;

          for (final doodle in doodles) {
            if (doodle.pontos.isEmpty ||
                doodle.ferramenta.startsWith('text:')) {
              continue;
            }

            final isHighlight = doodle.ferramenta == 'highlight';
            final opacity = isHighlight ? 0.08 : 0.30;

            canvas.setStrokeColor(
              PdfColor.fromInt(doodle.cor.value).withAlpha(opacity),
            );
            canvas.setLineWidth(isHighlight ? 15 : 2);
            canvas.setLineCap(PdfLineCap.round);

            // CORREÇÃO: Aplicar a mesma lógica de inversão para desenhos
            final path = doodle.pontos.map((p) {
              final dx = p.dx * pageWidth;
              final dy = (1.0 - p.dy) * pageHeight; // Inverte o eixo Y
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

  List<pw.Widget> _buildTextAnnotationsScaled(
    int page,
    double drawWidth,
    double drawHeight,
  ) {
    final doodles = _desenhosPorPagina[page] ?? [];

    return doodles.where((d) => d.ferramenta.startsWith('text:')).map((doodle) {
      final p = doodle.pontos.first;

      // CORREÇÃO: Aplicar a mesma lógica de inversão para textos
      final pdfX = p.dx * drawWidth;
      final pdfY = (1.0 - p.dy) * drawHeight; // Inverte o eixo Y

      const fontSize = 18.0;

      return pw.Positioned(
        left: pdfX,
        top: pdfY - fontSize * 0.7, // Ajuste fino para alinhamento visual
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
                  pageLayoutMode: PdfPageLayoutMode.single,
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
                    // Regras:
                    // - modo leitura (_modoEdicao == false): overlay ignora toques (para navegação por bordas funcionar)
                    // - modo edição + texto: overlay ignora toques (tap é do viewer para texto)
                    // - modo edição com outras ferramentas: overlay recebe pan/touch para desenhar
                    final ignorarOverlay =
                        !_modoEdicao || _ferramentaAtiva == 'text';

                    return IgnorePointer(
                      ignoring: ignorarOverlay,
                      child: DrawingCanvas(
                        ferramenta: _ferramentaAtiva,
                        cor: _corAtiva,
                        podeDesenhar: _modoEdicao && _ferramentaAtiva != 'text',
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
