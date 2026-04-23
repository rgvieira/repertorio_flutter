import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Doodle guarda coordenadas NORMALIZADAS (0..1) relativas ao canvas:
/// - pontos[i].dx: fração de 0 a 1 da largura
/// - pontos[i].dy: fração de 0 a 1 da altura
class Doodle {
  final List<Offset> pontos; // frações 0..1
  final Color cor;
  final String ferramenta;

  Doodle(this.pontos, this.cor, this.ferramenta);

  Map<String, dynamic> toMap() {
    return {
      'pontos': pontos
          .map((p) => {
                'x': p.dx,
                'y': p.dy,
              })
          .toList(),
      'cor': cor.value,
      'ferramenta': ferramenta,
    };
  }

  factory Doodle.fromMap(Map<dynamic, dynamic> map) {
    return Doodle(
      (map['pontos'] as List)
          .map((p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ))
          .toList(),
      Color(map['cor']),
      map['ferramenta'],
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  final String ferramenta;
  final Color cor;
  final Function(Doodle) aoFinalizar;
  final List<Doodle> historico;
  final bool podeDesenhar;

  const DrawingCanvas({
    super.key,
    required this.ferramenta,
    required this.cor,
    required this.aoFinalizar,
    required this.historico,
    required this.podeDesenhar,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _pontosAtuais = [];

  // guardamos o tamanho do canvas pra normalizar
  double _canvasWidth = 1;
  double _canvasHeight = 1;

  // converte um ponto em pixels para frações 0..1 do canvas
  Offset _toNormalized(Offset p) {
    final w = _canvasWidth == 0 ? 1 : _canvasWidth;
    final h = _canvasHeight == 0 ? 1 : _canvasHeight;
    return Offset(p.dx / w, p.dy / h);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _canvasWidth = constraints.maxWidth;
        _canvasHeight = constraints.maxHeight;

        return GestureDetector(
          onPanStart: !widget.podeDesenhar
              ? null
              : (details) {
                  if (widget.ferramenta == 'text') {
                    // texto agora é criado pelo onTap do SfPdfViewer,
                    // não desenhamos texto aqui
                    return;
                  } else {
                    setState(
                      () => _pontosAtuais = [details.localPosition],
                    );
                  }
                },
          onPanUpdate: !widget.podeDesenhar
              ? null
              : (details) {
                  if (widget.ferramenta != 'text') {
                    setState(
                      () => _pontosAtuais.add(details.localPosition),
                    );
                  }
                },
          onPanEnd: !widget.podeDesenhar
              ? null
              : (details) {
                  if (_pontosAtuais.isNotEmpty &&
                      widget.ferramenta != 'text') {
                    final normalizedPoints =
                        _pontosAtuais.map(_toNormalized).toList();
                    widget.aoFinalizar(
                      Doodle(
                        normalizedPoints,
                        widget.cor,
                        widget.ferramenta,
                      ),
                    );
                  }
                  setState(() => _pontosAtuais = []);
                },
          child: CustomPaint(
            painter: MyPainter(
              widget.historico,
              _pontosAtuais,
              widget.cor,
              widget.ferramenta,
            ),
            child: Container(color: Colors.transparent),
          ),
        );
      },
    );
  }
}

class MyPainter extends CustomPainter {
  final List<Doodle> historico;
  final List<Offset> atual; // traço atual em pixels
  final Color corAtiva;
  final String ferramentaAtiva;

  MyPainter(this.historico, this.atual, this.corAtiva, this.ferramentaAtiva);

  @override
  void paint(Canvas canvas, Size size) {
    // desenha histórico: precisa desnormalizar (frações 0..1 -> pixels)
    for (var doodle in historico) {
      final pts = doodle.pontos
          .map(
            (p) => Offset(
              p.dx * size.width,
              p.dy * size.height,
            ),
          )
          .toList();
      _drawDoodle(canvas, pts, doodle.cor, doodle.ferramenta);
    }

    // desenha traço atual (ainda em pixels brutos)
    _drawDoodle(canvas, atual, corAtiva, ferramentaAtiva);
  }

  void _drawDoodle(Canvas canvas, List<Offset> pts, Color color, String tool) {
    if (pts.isEmpty) return;

    final paint = Paint()
      ..color = tool == 'highlight' ? color.withOpacity(0.1) : color
      ..strokeWidth = tool == 'highlight' ? 25 : 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // texto
    if (tool.startsWith('text:')) {
      final textPainter = TextPainter(
        text: TextSpan(
          text: tool.substring(5),
          style: TextStyle(
            color: color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      const double baselineOffset = 12;
      final Offset drawPos = Offset(
        pts.first.dx,
        pts.first.dy - baselineOffset,
      );

      textPainter.paint(canvas, drawPos);
      return;
    }

    switch (tool) {
      case 'pen':
      case 'highlight':
        for (int i = 0; i < pts.length - 1; i++) {
          canvas.drawLine(pts[i], pts[i + 1], paint);
        }
        break;

      case 'circle':
        if (pts.length > 1) {
          final center = Offset(
            (pts.first.dx + pts.last.dx) / 2,
            (pts.first.dy + pts.last.dy) / 2,
          );
          final radius = math.min(
                (pts.last.dx - pts.first.dx).abs(),
                (pts.last.dy - pts.first.dy).abs(),
              ) /
              2;
          canvas.drawCircle(center, radius, paint);
        }
        break;

      case 'line':
        if (pts.length > 1) {
          canvas.drawLine(pts.first, pts.last, paint);
        }
        break;

      case 'arrow':
        if (pts.length > 1) {
          final start = pts.first;
          final end = pts.last;
          canvas.drawLine(start, end, paint);
          final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
          canvas.drawPath(
            Path()
              ..moveTo(
                end.dx - 15 * math.cos(angle - 0.5),
                end.dy - 15 * math.sin(angle - 0.5),
              )
              ..lineTo(end.dx, end.dy)
              ..lineTo(
                end.dx - 15 * math.cos(angle + 0.5),
                end.dy - 15 * math.sin(angle + 0.5),
              ),
            paint,
          );
        }
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}