import 'package:flutter/material.dart';
import 'dart:math' as math;

// ESTA CLASSE TEM QUE ESTAR AQUI FORA
class Doodle {
  final List<Offset> pontos;
  final Color cor;
  final String ferramenta;
  Doodle(this.pontos, this.cor, this.ferramenta);
}

class DrawingCanvas extends StatefulWidget {
  final String ferramenta;
  final Color cor;
  final Function(Doodle) aoFinalizar;
  final List<Doodle> historico;

  const DrawingCanvas({
    super.key,
    required this.ferramenta,
    required this.cor,
    required this.aoFinalizar,
    required this.historico,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _pontosAtuais = [];

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) =>
          setState(() => _pontosAtuais = [details.localPosition]),
      onPanUpdate: (details) =>
          setState(() => _pontosAtuais.add(details.localPosition)),
      onPanEnd: (details) {
        if (_pontosAtuais.isNotEmpty) {
          widget.aoFinalizar(
              Doodle(List.from(_pontosAtuais), widget.cor, widget.ferramenta));
        }
        setState(() => _pontosAtuais = []);
      },
      child: CustomPaint(
        painter: MyPainter(
            widget.historico, _pontosAtuais, widget.cor, widget.ferramenta),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

class MyPainter extends CustomPainter {
  final List<Doodle> historico;
  final List<Offset> atual;
  final Color corAtiva;
  final String ferramentaAtiva;

  MyPainter(this.historico, this.atual, this.corAtiva, this.ferramentaAtiva);

  @override
  void paint(Canvas canvas, Size size) {
    for (var doodle in historico) {
      _drawDoodle(canvas, doodle.pontos, doodle.cor, doodle.ferramenta);
    }
    _drawDoodle(canvas, atual, corAtiva, ferramentaAtiva);
  }

  void _drawDoodle(Canvas canvas, List<Offset> pts, Color color, String tool) {
    if (pts.isEmpty) return;
    final paint = Paint()
      ..color = tool == 'highlight' ? color.withOpacity(0.5) : color
      ..strokeWidth = tool == 'highlight' ? 25 : 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (tool == 'pen' || tool == 'highlight') {
      for (int i = 0; i < pts.length - 1; i++) {
        canvas.drawLine(pts[i], pts[i + 1], paint);
      }
    } else if (tool == 'arrow' && pts.length > 1) {
      final start = pts.first;
      final end = pts.last;
      canvas.drawLine(start, end, paint);
      final angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
      canvas.drawPath(
        Path()
          ..moveTo(end.dx - 15 * math.cos(angle - 0.5),
              end.dy - 15 * math.sin(angle - 0.5))
          ..lineTo(end.dx, end.dy)
          ..lineTo(end.dx - 15 * math.cos(angle + 0.5),
              end.dy - 15 * math.sin(angle + 0.5)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
