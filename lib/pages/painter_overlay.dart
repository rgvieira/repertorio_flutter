import 'package:flutter/material.dart';
import 'dart:math' as math;

class Doodle {
  final List<Offset> pontos;
  final Color cor;
  final String ferramenta;

  Doodle(this.pontos, this.cor, this.ferramenta);

  // CONVERTE PARA GRAVAR NO HIVE
  Map<String, dynamic> toMap() {
    return {
      'pontos': pontos.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'cor': cor.value,
      'ferramenta': ferramenta,
    };
  }

  // RECUPERA DO HIVE
  factory Doodle.fromMap(Map<dynamic, dynamic> map) {
    return Doodle(
      (map['pontos'] as List).map((p) => Offset(p['x'], p['y'])).toList(),
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
  final bool podeDesenhar; // ADICIONADO AQUI

  const DrawingCanvas({
    super.key,
    required this.ferramenta,
    required this.cor,
    required this.aoFinalizar,
    required this.historico,
    required this.podeDesenhar, // OBRIGATÓRIO AGORA
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _pontosAtuais = [];

  // Função para abrir o teclado e capturar texto
  Future<String?> _pedirTexto(BuildContext context) async {
    TextEditingController controller = TextEditingController();
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
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // Se podeDesenhar for FALSO, o toque passa direto para o PDF (scroll/zoom)
      onPanStart: !widget.podeDesenhar
          ? null
          : (details) async {
              if (widget.ferramenta == 'text') {
                String? texto = await _pedirTexto(context);
                if (texto != null && texto.isNotEmpty) {
                  widget.aoFinalizar(Doodle(
                      [details.localPosition], widget.cor, "text:$texto"));
                }
              } else {
                setState(() => _pontosAtuais = [details.localPosition]);
              }
            },
      onPanUpdate: !widget.podeDesenhar
          ? null
          : (details) {
              if (widget.ferramenta != 'text') {
                setState(() => _pontosAtuais.add(details.localPosition));
              }
            },
      onPanEnd: !widget.podeDesenhar
          ? null
          : (details) {
              if (_pontosAtuais.isNotEmpty && widget.ferramenta != 'text') {
                widget.aoFinalizar(Doodle(
                    List.from(_pontosAtuais), widget.cor, widget.ferramenta));
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
      ..color = tool == 'highlight' ? color.withValues(alpha: 0.1) : color
      ..strokeWidth = tool == 'highlight' ? 25 : 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Texto
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
      textPainter.paint(canvas, pts.first);
      return;
    }

    // Tipos de desenho
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
