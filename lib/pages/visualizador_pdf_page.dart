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
  double _espessuraAtiva = 2.0;
  String? _objetoSelecionadoId; // ID do objeto selecionado para mover

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

  /// Calcula o retângulo onde o PDF realmente está sendo desenhado na tela
  Rect _getActualPdfRect(Size viewSize, {int? pageNumber}) {
    final targetPage = pageNumber ?? _paginaAtual;
    if (_pdfDocument == null || _totalPaginas == 0 || targetPage < 1)
      return Rect.zero;

    final page = _pdfDocument!.pages[targetPage - 1];
    final pdfW = page.size.width;
    final pdfH = page.size.height;
    final pdfAspect = pdfW / pdfH;

    final viewW = viewSize.width;
    final viewH = viewSize.height;
    final viewAspect = viewW / viewH;

    double drawW, drawH;
    if (pdfAspect > viewAspect) {
      drawW = viewW;
      drawH = viewW / pdfAspect;
    } else {
      drawH = viewH;
      drawW = viewH * pdfAspect;
    }

    final offsetX = (viewW - drawW) / 2;
    final offsetY = (viewH - drawH) / 2;

    return Rect.fromLTWH(offsetX, offsetY, drawW, drawH);
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

    // 1) Navegação por borda (Somente fora do modo edição)
    // Executado no início para permitir navegação mesmo tocando no fundo/margens do visualizador
    if (!_modoEdicao) {
      final xRatio = localPos.dx / viewSize.width;
      if (xRatio < 0.15) {
        // 15% da margem esquerda
        _pdfController.previousPage();
        return;
      } else if (xRatio > 0.85) {
        // 15% da margem direita
        _pdfController.nextPage();
        return;
      }
    }

    // 1) Página PDF atual
    final pdfRect = _getActualPdfRect(viewSize, pageNumber: details.pageNumber);
    if (pdfRect == Rect.zero) return;

    // 3) Coordenadas relativas dentro dessa área
    final relX = (localPos.dx - pdfRect.left).clamp(0.0, pdfRect.width);
    final relY = (localPos.dy - pdfRect.top).clamp(0.0, pdfRect.height);

    final xNorm = (relX / pdfRect.width).clamp(0.0, 1.0);
    final yNorm = (relY / pdfRect.height).clamp(0.0, 1.0);

    // 4) Texto em modo edição
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

    // 6) Caso contrário, não faz nada
  }

  Future<void> _imprimirComAnotacoes() async {
    try {
      final originalBytes = await File(widget.filePath).readAsBytes();
      final pw.Document pdfOutput = pw.Document();

      // Rasteriza todas as páginas
      final pages = await Printing.raster(
        originalBytes,
        dpi: 144,
      ).toList();

      const PdfPageFormat targetFormat = PdfPageFormat.a4;

      for (int i = 0; i < pages.length; i++) {
        final rasterPage = pages[i];
        final currentPage = i + 1;

        // Tamanho da página rasterizada
        final srcWidth = rasterPage.width.toDouble();
        final srcHeight = rasterPage.height.toDouble();
        final srcAspect = srcWidth / srcHeight;

        // Tamanho do A4
        final dstWidth = targetFormat.width;
        final dstHeight = targetFormat.height;
        final dstAspect = dstWidth / dstHeight;

        // Rect do PDF original dentro do A4
        double drawWidth;
        double drawHeight;
        if (srcAspect > dstAspect) {
          drawWidth = dstWidth;
          drawHeight = dstWidth / srcAspect;
        } else {
          drawHeight = dstHeight;
          drawWidth = dstHeight * srcAspect;
        }

        final offsetX = (dstWidth - drawWidth) / 2;
        final offsetY = (dstHeight - drawHeight) / 2;

        pdfOutput.addPage(
          pw.Page(
            pageFormat: targetFormat,
            margin: pw.EdgeInsets.zero,
            build: (pw.Context context) {
              return pw.Stack(
                children: [
                  // Página original centralizada
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

                  // Textos
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
            final opacity = isHighlight ? 0.03 : 0.30;

            canvas.setStrokeColor(
              PdfColor.fromInt(doodle.cor.toARGB32()).withAlpha(opacity),
            );
            // Usa a espessura do doodle, com valores padrão apropriados
            double lineWidth;
            if (isHighlight) {
              lineWidth = 15;
            } else {
              // Converte espessura da tela (1-10) para PDF (1-5 pontos)
              lineWidth = doodle.espessura * 0.5;
              if (lineWidth < 1) lineWidth = 1;
              if (lineWidth > 5) lineWidth = 5;
            }
            canvas.setLineWidth(lineWidth);
            canvas.setLineCap(PdfLineCap.round);

            final path = doodle.pontos.map((p) {
              final dx = p.dx * pageWidth;
              final dy =
                  (1.0 - p.dy) * pageHeight; // Inversão para o sistema PDF
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

      final pdfX = p.dx * drawWidth;
      final pdfY = p.dy * drawHeight; // SEM inversão

      const fontSize = 18.0;

      return pw.Positioned(
        left: pdfX,
        top: pdfY - fontSize * 0.7,
        child: pw.Text(
          doodle.ferramenta.substring(5),
          style: pw.TextStyle(
            color: PdfColor.fromInt(doodle.cor.toARGB32()),
            fontSize: fontSize,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildToolButton(String tool, IconData icon, String tooltip) {
    final scheme = Theme.of(context).colorScheme;
    final isActive = _ferramentaAtiva == tool;

    if (isActive) {
      return IconButton.filledTonal(
        icon: Icon(icon, size: 24, color: scheme.onSecondaryContainer),
        style: IconButton.styleFrom(
          backgroundColor: scheme.secondaryContainer,
        ),
        onPressed: () => setState(() => _ferramentaAtiva = tool),
        tooltip: tooltip,
      );
    }
    return IconButton(
      icon: Icon(icon, size: 24, color: scheme.primary),
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

  void _escolherEspessura() {
    double espessuraTemp = _espessuraAtiva;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Espessura da Linha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                value: espessuraTemp,
                min: 1.0,
                max: 10.0,
                divisions: 9,
                label: espessuraTemp.toStringAsFixed(1),
                onChanged: (value) {
                  setDialogState(() => espessuraTemp = value);
                },
              ),
              Container(
                height: 40,
                child: CustomPaint(
                  painter: _EspessuraPreviewPainter(espessuraTemp, _corAtiva),
                  size: const Size(double.infinity, 40),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _espessuraAtiva = espessuraTemp);
                Navigator.pop(context);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      ),
    );
  }

  /// Gera um ID único para um doodle baseado em seus pontos
  String _gerarDoodleId(Doodle d) {
    if (d.pontos.isEmpty) return '';
    final primeiro = d.pontos.first;
    return '${d.ferramenta}_${primeiro.dx.toStringAsFixed(4)}_${primeiro.dy.toStringAsFixed(4)}';
  }

  /// Encontra o doodle mais próximo de um ponto (em coordenadas normalizadas 0-1)
  int? _encontrarDoodleMaisProximo(Offset pontoNormalizado, double tolerancia) {
    final doodles = _desenhosPorPagina[_paginaAtual] ?? [];
    if (doodles.isEmpty) return null;

    int? indiceMaisProximo;
    double menorDistancia = tolerancia;

    for (int i = 0; i < doodles.length; i++) {
      final doodle = doodles[i];
      if (doodle.pontos.isEmpty) continue;

      // Para cada doodle, encontra o ponto mais próximo
      double menorDistanciaNesteDoodle = double.infinity;
      for (final ponto in doodle.pontos) {
        final distancia = (ponto - pontoNormalizado).distance;
        if (distancia < menorDistanciaNesteDoodle) {
          menorDistanciaNesteDoodle = distancia;
        }
      }

      if (menorDistanciaNesteDoodle < menorDistancia) {
        menorDistancia = menorDistanciaNesteDoodle;
        indiceMaisProximo = i;
      }
    }

    return indiceMaisProximo;
  }

  /// Canvas para mover objetos
  Widget _buildMoveCanvas(BoxConstraints constraints) {
    final size = Size(constraints.maxWidth, constraints.maxHeight);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) {
        // Seleciona imediatamente ao começar a arrastar
        final local = details.localPosition;
        final x = (local.dx / size.width).clamp(0.0, 1.0);
        final y = (local.dy / size.height).clamp(0.0, 1.0);
        final indice = _encontrarDoodleMaisProximo(Offset(x, y), 0.05);
        if (indice != null) {
          setState(() => _objetoSelecionadoId =
              _gerarDoodleId(_desenhosPorPagina[_paginaAtual]![indice]));
        }
      },
      onTapUp: (details) {
        // Selecionar objeto ao tocar
        final local = details.localPosition;
        final x = (local.dx / size.width).clamp(0.0, 1.0);
        final y = (local.dy / size.height).clamp(0.0, 1.0);
        final ponto = Offset(x, y);

        final indice = _encontrarDoodleMaisProximo(ponto, 0.05);
        setState(() {
          if (indice != null) {
            _objetoSelecionadoId =
                _gerarDoodleId(_desenhosPorPagina[_paginaAtual]![indice]);
          } else {
            _objetoSelecionadoId = null;
          }
        });
      },
      onPanUpdate: (details) {
        // Mover objeto
        if (_objetoSelecionadoId == null) return;

        final delta = details.delta;
        final deltaX = delta.dx / size.width;
        final deltaY = delta.dy / size.height;

        setState(() {
          final doodles = _desenhosPorPagina[_paginaAtual] ?? [];
          for (int i = 0; i < doodles.length; i++) {
            if (_gerarDoodleId(doodles[i]) == _objetoSelecionadoId) {
              final pontosOriginais = doodles[i].pontos;
              final novosPontos = pontosOriginais.map((p) {
                return Offset(
                  (p.dx + deltaX).clamp(0.0, 1.0),
                  (p.dy + deltaY).clamp(0.0, 1.0),
                );
              }).toList();
              final novoDoodle = Doodle(
                novosPontos,
                doodles[i].cor,
                doodles[i].ferramenta,
                espessura: doodles[i].espessura,
              );
              doodles[i] = novoDoodle;
              _objetoSelecionadoId = _gerarDoodleId(
                  novoDoodle); // Mantém o ID atualizado para o próximo frame
              break;
            }
          }
        });
      },
      onPanEnd: (_) {
        if (_objetoSelecionadoId != null) {
          _salvarNoBanco();
        }
      },
      child: CustomPaint(
        size: size,
        painter: _MoveOverlayPainter(
          historico: _desenhosPorPagina[_paginaAtual] ?? [],
          objetoSelecionadoId: _objetoSelecionadoId,
          corDestaque: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box box, _) {
        final modoNoite = box.get('modoNoite', defaultValue: false);
        final horizontal = box.get('horizontal', defaultValue: false);

        return Scaffold(
          backgroundColor: modoNoite
              ? Colors.black
              : scheme.surface, // Cinza escuro padrão PDF para contraste
          appBar: AppBar(
            titleSpacing: 0,
            backgroundColor: scheme.primary, // opcional, se quiser forçar
            foregroundColor: scheme.onPrimary,
            title: Text(
              widget.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onPrimary,
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.print,
                  color: scheme.onPrimary,
                ),
                onPressed: _imprimirComAnotacoes,
              ),
              IconButton(
                icon: Icon(
                  _modoEdicao ? Icons.brush : Icons.edit_off,
                  color: _modoEdicao ? Colors.orange : scheme.onPrimary,
                ),
                onPressed: () => setState(() => _modoEdicao = !_modoEdicao),
              ),
            ],
          ),
          bottomNavigationBar: BottomAppBar(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new),
                    onPressed: () => _pdfController.previousPage(),
                  ),
                  Text(
                    "Página $_paginaAtual de $_totalPaginas",
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios),
                    onPressed: () => _pdfController.nextPage(),
                  ),
                ],
              ),
            ),
          ),
          body: Stack(
            children: [
              _buildPdfViewer(modoNoite, horizontal),

              // OVERLAY DE DESENHO E MOVIMENTO
              // IgnorePointer garante que em modo leitura os toques passem direto para o PDF
              IgnorePointer(
                ignoring: !_modoEdicao,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final viewSize =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    final pdfRect = _getActualPdfRect(viewSize);

                    if (pdfRect == Rect.zero) return const SizedBox.shrink();

                    final ehFerramentaMover = _ferramentaAtiva == 'move';
                    final podeDesenhar = _modoEdicao &&
                        _ferramentaAtiva != 'text' &&
                        _ferramentaAtiva != 'move';

                    return Stack(
                      children: [
                        Positioned.fromRect(
                          rect: pdfRect,
                          child: IgnorePointer(
                            ignoring: !podeDesenhar,
                            child: DrawingCanvas(
                              ferramenta: _ferramentaAtiva,
                              cor: _corAtiva,
                              espessura: _espessuraAtiva,
                              podeDesenhar: podeDesenhar,
                              historico: _desenhosPorPagina[_paginaAtual] ?? [],
                              aoFinalizar: (novoDoodle) {
                                setState(() {
                                  if (_ferramentaAtiva == 'eraser') {
                                    _desenhosPorPagina[_paginaAtual]
                                        ?.removeWhere(
                                      (d) => d.pontos.any(
                                        (p) =>
                                            (p - novoDoodle.pontos.first)
                                                .distance <
                                            0.05,
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
                          ),
                        ),
                        if (ehFerramentaMover)
                          Positioned.fromRect(
                            rect: pdfRect,
                            child: _buildMoveCanvas(
                                BoxConstraints.tight(pdfRect.size)),
                          ),
                      ],
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
                        backgroundColor: scheme.primary,
                        foregroundColor: scheme.onPrimary,
                        onPressed: () {
                          setState(() {
                            _mostrarPainelFerramentas =
                                !_mostrarPainelFerramentas;
                          });
                        },
                        child: Icon(
                          _mostrarPainelFerramentas ? Icons.close : Icons.brush,
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
                                IconButton(
                                  icon: Icon(
                                    Icons.line_weight,
                                    color: _ferramentaAtiva == 'line' ||
                                            _ferramentaAtiva == 'arrow'
                                        ? Colors.orange
                                        : scheme.primary,
                                  ),
                                  onPressed: _escolherEspessura,
                                  tooltip: 'Espessura da linha',
                                ),
                                _buildToolButton('line', Icons.remove, 'Linha'),
                                _buildToolButton(
                                    'arrow', Icons.trending_flat, 'Seta'),
                                _buildToolButton(
                                    'text', Icons.text_fields, 'Texto'),
                                _buildToolButton(
                                    'move', Icons.drag_indicator, 'Mover'),
                                const Divider(),
                                IconButton(
                                  icon: Icon(Icons.palette, color: _corAtiva),
                                  onPressed: _escolherCor,
                                  tooltip: 'Escolher cor',
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
                                  tooltip: 'Limpar página',
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

  Widget _buildPdfViewer(bool modoNoite, bool horizontal) {
    final viewer = Container(
      color: Colors.white, // Garante o fundo branco sólido atrás das páginas
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
    );

    if (!modoNoite) return viewer;

    return ColorFiltered(
      colorFilter: const ColorFilter.matrix([
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
      ]),
      child: viewer,
    );
  }
}

/// Painter para preview de espessura
class _EspessuraPreviewPainter extends CustomPainter {
  final double espessura;
  final Color cor;

  _EspessuraPreviewPainter(this.espessura, this.cor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = cor
      ..strokeWidth = espessura
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final centroY = size.height / 2;
    canvas.drawLine(
      Offset(10, centroY),
      Offset(size.width - 10, centroY),
      paint,
    );
  }

  @override
  bool shouldRepaint(_EspessuraPreviewPainter oldDelegate) {
    return oldDelegate.espessura != espessura || oldDelegate.cor != cor;
  }
}

/// Painter para overlay de movimento (mostra objetos e destaca o selecionado)
class _MoveOverlayPainter extends CustomPainter {
  final List<Doodle> historico;
  final String? objetoSelecionadoId;
  final Color corDestaque;

  _MoveOverlayPainter({
    required this.historico,
    required this.objetoSelecionadoId,
    required this.corDestaque,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final doodle in historico) {
      final id = _gerarDoodleId(doodle);
      final selecionado = id == objetoSelecionadoId;

      if (doodle.pontos.isEmpty) continue;

      // Pula texto (não move texto neste modo)
      if (doodle.ferramenta.startsWith('text:')) continue;

      final paint = Paint()
        ..color = doodle.cor.withOpacity(selecionado ? 0.8 : 0.5)
        ..strokeWidth = doodle.ferramenta == 'highlight' ? 10 : doodle.espessura
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final pontosTela = doodle.pontos
          .map((p) => Offset(p.dx * size.width, p.dy * size.height))
          .toList();

      // Desenha bounding box se selecionado
      if (selecionado && pontosTela.length >= 2) {
        final minX =
            pontosTela.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
        final maxX =
            pontosTela.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
        final minY =
            pontosTela.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
        final maxY =
            pontosTela.map((p) => p.dy).reduce((a, b) => a > b ? a : b);
        final padding = 10.0;
        final rect = Rect.fromLTRB(
          minX - padding,
          minY - padding,
          maxX + padding,
          maxY + padding,
        );
        canvas.drawRect(
          rect,
          Paint()
            ..color = Colors.blue.withOpacity(0.3)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1
            ..strokeCap = StrokeCap.round,
        );
      }

      // Desenha o doodle
      switch (doodle.ferramenta) {
        case 'circle':
          if (pontosTela.length >= 2) {
            final p1 = pontosTela.first;
            final p2 = pontosTela.last;
            final rect = Rect.fromPoints(p1, p2);
            canvas.drawOval(rect, paint);
          }
          break;

        case 'line':
        case 'arrow':
          if (pontosTela.length >= 2) {
            final p1 = pontosTela.first;
            final p2 = pontosTela.last;
            canvas.drawLine(p1, p2, paint);

            if (doodle.ferramenta == 'arrow') {
              final angle = math.atan2(p2.dy - p1.dy, p2.dx - p1.dx);
              const arrowSize = 10.0;
              final path = Path()
                ..moveTo(
                  p2.dx - arrowSize * math.cos(angle - 0.5),
                  p2.dy - arrowSize * math.sin(angle - 0.5),
                )
                ..lineTo(p2.dx, p2.dy)
                ..lineTo(
                  p2.dx - arrowSize * math.cos(angle + 0.5),
                  p2.dy - arrowSize * math.sin(angle + 0.5),
                );
              canvas.drawPath(path, paint);
            }
          }
          break;

        default: // pen, highlight
          final path = Path()..moveTo(pontosTela.first.dx, pontosTela.first.dy);
          for (int i = 1; i < pontosTela.length; i++) {
            path.lineTo(pontosTela[i].dx, pontosTela[i].dy);
          }
          canvas.drawPath(path, paint);
          break;
      }
    }
  }

  String _gerarDoodleId(Doodle d) {
    if (d.pontos.isEmpty) return '';
    final primeiro = d.pontos.first;
    return '${d.ferramenta}_${primeiro.dx.toStringAsFixed(4)}_${primeiro.dy.toStringAsFixed(4)}';
  }

  @override
  bool shouldRepaint(_MoveOverlayPainter oldDelegate) {
    return oldDelegate.historico != historico ||
        oldDelegate.objetoSelecionadoId != objetoSelecionadoId;
  }
}
