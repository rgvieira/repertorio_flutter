import 'package:flutter/material.dart';
import 'dart:math' as math;

class Doodle {
  final List<Offset> pontos; // sempre 0–1
  final Color cor;
  final String ferramenta;
  final double espessura; // espessura da linha em pixels (na tela)

  Doodle(this.pontos, this.cor, this.ferramenta, {this.espessura = 2.0});

  Map<String, dynamic> toMap() => {
        'pontos': pontos.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
        'cor': cor.toARGB32(),
        'ferramenta': ferramenta,
        'espessura': espessura,
      };

  factory Doodle.fromMap(Map<String, dynamic> map) {
    return Doodle(
      (map['pontos'] as List)
          .map((p) => Offset(
                (p['dx'] as num).toDouble(),
                (p['dy'] as num).toDouble(),
              ))
          .toList(),
      Color(map['cor'] as int),
      map['ferramenta'] as String,
      espessura: (map['espessura'] as num?)?.toDouble() ?? 2.0,
    );
  }
}

class DrawingCanvas extends StatefulWidget {
  final String ferramenta;
  final Color cor;
  final bool podeDesenhar;
  final List<Doodle> historico; // já em 0–1
  final void Function(Doodle) aoFinalizar;
  final double espessura; // espessura da linha

  const DrawingCanvas({
    super.key,
    required this.ferramenta,
    required this.cor,
    required this.podeDesenhar,
    required this.historico,
    required this.aoFinalizar,
    this.espessura = 2.0,
  });

  @override
  State<DrawingCanvas> createState() => _DrawingCanvasState();
}

class _DrawingCanvasState extends State<DrawingCanvas> {
  List<Offset> _pontosAtuais = [];

  void _start(DragStartDetails details, Size size) {
    if (!widget.podeDesenhar) return;
    if (widget.ferramenta == 'text') return; // texto é pelo onTap do PDF

    final local = details.localPosition;
    final x = (local.dx / size.width).clamp(0.0, 1.0);
    final y = (local.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _pontosAtuais = [Offset(x, y)];
    });
  }

  void _update(DragUpdateDetails details, Size size) {
    if (!widget.podeDesenhar || _pontosAtuais.isEmpty) return;
    if (widget.ferramenta == 'text') return;

    final local = details.localPosition;
    final x = (local.dx / size.width).clamp(0.0, 1.0);
    final y = (local.dy / size.height).clamp(0.0, 1.0);
    setState(() {
      _pontosAtuais.add(Offset(x, y));
    });
  }

  void _end(Size size) {
    if (!widget.podeDesenhar || _pontosAtuais.isEmpty) return;
    if (widget.ferramenta == 'text') {
      _pontosAtuais = [];
      return;
    }

    final doodle = Doodle(List.of(_pontosAtuais), widget.cor, widget.ferramenta,
        espessura: widget.espessura);
    widget.aoFinalizar(doodle);

    setState(() {
      _pontosAtuais = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanStart: (details) => _start(details, size),
          onPanUpdate: (details) => _update(details, size),
          onPanEnd: (_) => _end(size),
          child: CustomPaint(
            size: size,
            painter: _DoodlePainter(
              historico: widget.historico,
              pontosAtuais: _pontosAtuais,
              espessuraAtual: widget.espessura,
              corAtual: widget.cor,
              ferramentaAtual: widget.ferramenta,
            ),
          ),
        );
      },
    );
  }
}

class _DoodlePainter extends CustomPainter {
  final List<Doodle> historico;
  final List<Offset> pontosAtuais; // 0–1
  final double espessuraAtual;
  final Color corAtual;
  final String ferramentaAtual;

  _DoodlePainter({
    required this.historico,
    required this.pontosAtuais,
    required this.espessuraAtual,
    required this.corAtual,
    required this.ferramentaAtual,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Desenha tudo do histórico
    for (final doodle in historico) {
      _desenharDoodle(canvas, size, doodle);
    }

    // Desenha o doodle atual (em andamento)
    if (pontosAtuais.isNotEmpty) {
      _desenharDoodle(
        canvas,
        size,
        Doodle(
          pontosAtuais,
          corAtual,
          ferramentaAtual,
          espessura: espessuraAtual,
        ),
      );
    }
  }

  void _desenharDoodle(Canvas canvas, Size size, Doodle doodle) {
    if (doodle.pontos.isEmpty) return;

    // NOVO: desenhar texto se ferramenta começar com "text:"
    if (doodle.ferramenta.startsWith('text:')) {
      final texto = doodle.ferramenta.substring(5);
      final p = doodle.pontos.first;
      final dx = p.dx * size.width;
      final dy = p.dy * size.height;

      final textPainter = TextPainter(
        text: TextSpan(
          text: texto,
          style: TextStyle(
            color: doodle.cor,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        maxLines: 3,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: size.width * 0.8);

      textPainter.paint(
        canvas,
        Offset(dx, dy - textPainter.height * 0.7),
      );

      return; // não desenha linha/círculo etc. para este doodle
    }

    final paint = Paint()
      ..color = doodle.cor
          .withValues(alpha: doodle.ferramenta == 'highlight' ? 0.3 : 1.0)
      ..strokeWidth = doodle.ferramenta == 'highlight' ? 10 : doodle.espessura
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final pontosTela = doodle.pontos
        .map((p) => Offset(p.dx * size.width, p.dy * size.height))
        .toList();

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

  @override
  bool shouldRepaint(_DoodlePainter oldDelegate) {
    return oldDelegate.historico != historico ||
        oldDelegate.pontosAtuais != pontosAtuais ||
        oldDelegate.espessuraAtual != espessuraAtual ||
        oldDelegate.corAtual != corAtual ||
        oldDelegate.ferramentaAtual != ferramentaAtual;
  }
}
