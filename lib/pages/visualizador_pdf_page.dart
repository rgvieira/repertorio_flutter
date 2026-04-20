import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:hive_flutter/hive_flutter.dart';

// --- ESTE IMPORT É O QUE RESOLVE O SEU ERRO ---
// Ele traz as definições de 'Doodle' e 'DrawingCanvas' para cá
import 'painter_overlay.dart'; 

class VisualizadorPdfPage extends StatefulWidget {
  final String filePath;
  final String title;

  const VisualizadorPdfPage({super.key, required this.filePath, required this.title});

  @override
  State<VisualizadorPdfPage> createState() => _VisualizadorPdfPageState();
}

class _VisualizadorPdfPageState extends State<VisualizadorPdfPage> {
  final PdfViewerController _pdfController = PdfViewerController();
  bool _podeDesenhar = false; 
  
  // Aqui o 'Doodle' agora será reconhecido por causa do import acima
  List<Doodle> _desenhos = []; 

  @override
  Widget build(BuildContext context) {
    // Acessa a caixa de configurações do Hive
    var settingsBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box b, _) {
        // Busca as preferências ou usa o padrão (false)
        bool modoNoite = b.get('modoNoite', defaultValue: false);
        bool horizontal = b.get('horizontal', defaultValue: false);

        return Scaffold(
          backgroundColor: modoNoite ? Colors.black : const Color(0xFF525659),
          appBar: AppBar(
            title: Text(widget.title),
            backgroundColor: const Color(0xFF186879),
            actions: [
              // Botão de "Cadeado" para liberar ou travar o desenho
              IconButton(
                icon: Icon(
                  _podeDesenhar ? Icons.edit : Icons.edit_off, 
                  color: _podeDesenhar ? Colors.orange : Colors.white
                ),
                onPressed: () => setState(() => _podeDesenhar = !_podeDesenhar),
              ),
            ],
          ),
          body: Stack(
            children: [
              // Filtro de cores para o Modo Noite (Inversão de Matriz)
              ColorFiltered(
                colorFilter: modoNoite 
                    ? const ColorFilter.matrix([
                        -1,  0,  0, 0, 255,
                         0, -1,  0, 0, 255,
                         0,  0, -1, 0, 255,
                         0,  0,  0, 1, 0,
                      ])
                    : const ColorFilter.mode(Colors.transparent, BlendMode.multiply),
                child: SfPdfViewer.file(
                  File(widget.filePath),
                  controller: _pdfController,
                  // Aplica a paginação horizontal ou vertical vinda do Hive
                  scrollDirection: horizontal ? PdfScrollDirection.horizontal : PdfScrollDirection.vertical,
                  pageLayoutMode: horizontal ? PdfPageLayoutMode.single : PdfPageLayoutMode.continuous,
                ),
              ),
              
              // O 'DrawingCanvas' agora será reconhecido por causa do import
              if (_podeDesenhar)
                Positioned.fill(
                  child: DrawingCanvas(
                    ferramenta: 'pen', // Você pode mudar para 'arrow', 'line', 'rect'
                    cor: Colors.red,
                    aoFinalizar: (novoDoodle) {
                      setState(() {
                        _desenhos.add(novoDoodle);
                      });
                    },
                    historico: _desenhos,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}