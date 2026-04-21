import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:scanpastas_flutter/pages/biblioteca_page.dart';
import 'package:scanpastas_flutter/pages/busca_page.dart';
import 'package:scanpastas_flutter/pages/configuracoes_page.dart';
import 'package:scanpastas_flutter/pages/detalhes_pasta_page.dart';
import 'package:scanpastas_flutter/pages/repertorio_page.dart';
import 'package:scanpastas_flutter/pages/ajuda_page.dart';
import 'package:scanpastas_flutter/widgets/file_list_item.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('minha_biblioteca');
  await Hive.openBox('settings');

  runApp(const ScanPastasApp());
}

class ScanPastasApp extends StatelessWidget {
  const ScanPastasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF186879),
          primary: const Color(0xFF186879),
        ),
        fontFamily: 'Manrope',
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String nomePrincipal = "Repertório";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('minha_biblioteca');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        final List<Map> pastasRaiz = b.values
            .where((item) => item is Map && item['tipo'] == 'root')
            .cast<Map>()
            .toList();

        final bool temFavorita =
            pastasRaiz.any((item) => item['favorita'] == true);

        final int tabCount = temFavorita ? 3 : 2;

        return DefaultTabController(
          length: tabCount,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context)!;

              return AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  final currentTitle =
                      _getTitle(tabController.index, temFavorita);

                  return Scaffold(
                    appBar: AppBar(
                      backgroundColor: const Color(0xFF186879),
                      foregroundColor: Colors.white,
                      title: Text(
                        currentTitle,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      actions: [
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BuscaPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.help_outline),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AjudaPage(),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.settings),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ConfiguracoesPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      bottom: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: [
                          if (temFavorita)
                            const Tab(
                              icon: Icon(Icons.home),
                              text: 'Favorita',
                            ),
                          const Tab(
                            icon: Icon(Icons.library_books),
                            text: 'Biblioteca',
                          ),
                          const Tab(
                            icon: Icon(Icons.music_note),
                            text: 'Repertório',
                          ),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      children: [
                        if (temFavorita)
                          _buildTelaPrincipal(context, pastasRaiz),
                        const BibliotecaPage(),
                        const RepertorioPage(),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  // Diálogo de busca
  void _showSearchDialog(BuildContext outerContext, Box box) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Buscar Arquivo'),
          content: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Digite o nome do arquivo ou pasta...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            autofocus: true,
            onSubmitted: (value) {
              _performSearch(outerContext, box, value);
              Navigator.pop(dialogContext);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _performSearch(outerContext, box, _searchController.text);
                Navigator.pop(dialogContext);
              },
              child: const Text('Buscar'),
            ),
          ],
        );
      },
    );
  }

  void _performSearch(BuildContext outerContext, Box box, String termo) {
    final termoLower = termo.toLowerCase().trim();
    if (termoLower.isEmpty) return;

    final resultados = <Map>[];

    for (final raw in box.values) {
      if (raw is! Map) continue;

      final map = raw.cast<String, dynamic>();
      final nome = (map['nome'] ?? '').toString().toLowerCase();

      if (nome.contains(termoLower)) {
        resultados.add({
          'pastaRaiz': map['rootPath'] ?? map['fullPath'] ?? 'Desconhecida',
          'nomeArquivo': map['nome'] ?? 'Sem nome',
          'fullPath': map['fullPath'] ?? map['rootPath'] ?? '',
          'id': map['_id'] ?? map['id'] ?? '',
        });
      }
    }

    if (resultados.isEmpty) {
      ScaffoldMessenger.of(outerContext).showSnackBar(
        SnackBar(
          content: Text(
            'Nenhum resultado encontrado para "$termo".',
          ),
        ),
      );
      return;
    }

    _showResultadosDialog(outerContext, resultados);
  }

  void _showResultadosDialog(BuildContext outerContext, List<Map> resultados) {
    showDialog(
      context: outerContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Resultados (${resultados.length})'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: resultados.length,
              itemBuilder: (context, index) {
                final item = resultados[index];
                return ListTile(
                  leading: const Icon(
                    Icons.folder,
                    color: Color(0xFF186879),
                  ),
                  title: Text(item['nomeArquivo']),
                  subtitle: Text(item['pastaRaiz']),
                  onTap: () {
                    Navigator.pop(dialogContext);
                    _navegarParaDetalhes(outerContext, item);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _navegarParaDetalhes(BuildContext context, Map item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetalhesPastaPage(
          rootPath: item['fullPath'].toString(),
          folderName: item['nomeArquivo'].toString(),
        ),
      ),
    );
  }

  String _getTitle(int index, bool temFavorita) {
    if (temFavorita) {
      return index == 0
          ? nomePrincipal
          : (index == 1 ? "Biblioteca" : "Repertório");
    } else {
      return index == 0 ? "Biblioteca" : "Repertório";
    }
  }

  Widget _buildTelaPrincipal(BuildContext context, List<Map> pastasRaiz) {
    final Box box = Hive.box('minha_biblioteca');

    Map? pastaFav;
    for (final item in pastasRaiz) {
      if (item['favorita'] == true) {
        pastaFav = item;
        break;
      }
    }

    if (pastaFav == null) {
      return const Center(child: Text("Nenhuma pasta raiz favoritada."));
    }

    final String rootPath = pastaFav['fullPath'].toString();
    final String nome = pastaFav['nome'].toString();

    return DetalhesPastaPage(
      rootPath: rootPath,
      folderName: nome,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
