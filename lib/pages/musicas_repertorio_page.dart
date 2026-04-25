import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repertorio_flutter/widgets/file_list_item.dart';

class MusicasRepertorioPage extends StatelessWidget {
  final String repertorioId;

  const MusicasRepertorioPage({super.key, required this.repertorioId});

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('minha_biblioteca');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
        title: ValueListenableBuilder(
          valueListenable: box.listenable(),
          builder: (context, Box b, _) {
            final repertorio = b.get(repertorioId);
            final nome = (repertorio is Map && repertorio['nome'] != null)
                ? repertorio['nome'].toString()
                : 'Repertório';
            return Text(
              nome,
              style: const TextStyle(fontWeight: FontWeight.w800),
            );
          },
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          // Busca o repertório
          final repertorio = b.get(repertorioId);
          if (repertorio == null || repertorio is! Map) {
            return const Center(
              child: Text(
                'Repertório não encontrado',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final List<dynamic> musicasIds = repertorio['musicas'] ?? [];

          if (musicasIds.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma música neste repertório',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          // Busca todos os arquivos pelos IDs
          final List<Map> musicas = [];
          for (final id in musicasIds) {
            final arquivo = b.get(id);
            if (arquivo is Map) {
              musicas.add(Map<String, dynamic>.from(arquivo));
            }
          }

          return Padding(
            padding: const EdgeInsets.all(8),
            child: ListView.separated(
              itemCount: musicas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final musica = musicas[index];
                return FileListItem(
                  item: musica,
                  showFavorite:
                      false, // ✅ não mostra o ícone de repertório aqui
                );
              },
            ),
          );
        },
      ),
    );
  }
}
