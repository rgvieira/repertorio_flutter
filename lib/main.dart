import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:scanpastas_flutter/pages/biblioteca_page.dart';
import 'package:scanpastas_flutter/pages/busca_page.dart';
import 'package:scanpastas_flutter/pages/configuracoes_page.dart';
import 'package:scanpastas_flutter/pages/detalhes_pasta_page.dart';
import 'package:scanpastas_flutter/pages/repertorio_page.dart';
import 'package:scanpastas_flutter/pages/ajuda_page.dart';
import 'package:scanpastas_flutter/pages/musicas_repertorio_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  await Hive.openBox('minha_biblioteca');
  await Hive.openBox('settings');
  await Hive.openBox('config_pdf'); // 

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
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('minha_biblioteca');

    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, Box b, _) {
        // PASTAS RAIZ
        final List<Map> pastasRaiz = b.values
            .where((item) => item is Map && item['tipo'] == 'root')
            .cast<Map>()
            .toList();

        final bool temFavorita =
            pastasRaiz.any((item) => item['favorita'] == true);

        // REPERTÓRIO FAVORITO
        final favoritoInfo = _getRepertorioFavorito(b);
        final String? repertorioFavId = favoritoInfo?['_id'];
        final bool temRepertorioFavorito = repertorioFavId != null;

        // Quantidade de abas (no máximo 4)
        final int tabCount = temFavorita
            ? (temRepertorioFavorito ? 4 : 3)
            : (temRepertorioFavorito ? 3 : 2);

        return DefaultTabController(
          length: tabCount,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context)!;

              return AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  final currentTitle = _getTitle(
                    tabController.index,
                    temFavorita,
                    temRepertorioFavorito,
                  );

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
                                builder: (context) =>
                                    const ConfiguracoesPage(),
                              ),
                            );
                          },
                        ),
                      ],
                      bottom: TabBar(
                        labelColor: Colors.white,
                        unselectedLabelColor: Colors.white70,
                        tabs: [
                          // 0 - Biblioteca Favorita (pasta raiz favorita)
                          if (temFavorita)
                            const Tab(
                              icon: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Icon(Icons.library_books),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              text: 'Biblioteca Favorita',
                            ),

                          // 1 - Repertório Favorito
                          if (temRepertorioFavorito)
                            const Tab(
                              icon: Stack(
                                alignment: Alignment.topRight,
                                children: [
                                  Icon(Icons.music_note),
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Icon(
                                      Icons.star,
                                      size: 12,
                                      color: Colors.amber,
                                    ),
                                  ),
                                ],
                              ),
                              text: 'Repertório Favorito',
                            ),

                          // 2 - Biblioteca
                          const Tab(
                            icon: Icon(Icons.library_books),
                            text: 'Biblioteca',
                          ),

                          // 3 - Repertório
                          const Tab(
                            icon: Icon(Icons.music_note),
                            text: 'Repertório',
                          ),
                        ],
                      ),
                    ),
                    body: TabBarView(
                      children: [
                        // 0 - Biblioteca Favorita (se existir)
                        if (temFavorita)
                          _buildTelaPrincipal(context, pastasRaiz),

                        // 1 - Repertório Favorito (se existir)
                        if (temRepertorioFavorito)
                          MusicasRepertorioPage(
                            repertorioId: repertorioFavId!,
                          ),

                        // 2 - Biblioteca
                        const BibliotecaPage(),

                        // 3 - Repertório
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

  Map<String, dynamic>? _getRepertorioFavorito(Box box) {
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final map = raw.cast<String, dynamic>();

      final type = (map['type'] ?? map['tipo'])?.toString();
      final bool isRepertorio = type == 'repertorio';
      final bool isFavorito = map['favoritoRepertorio'] == true;

      if (isRepertorio && isFavorito) {
        return map;
      }
    }
    return null;
  }

  String _getTitle(int index, bool temFavorita, bool temRepertorioFavorito) {
    // Ordem das abas:
    // [0] Biblioteca Favorita (se temFavorita)
    // [1] Repertório Favorito (se temRepertorioFavorito)
    // [2] Biblioteca
    // [3] Repertório

    if (temFavorita && temRepertorioFavorito) {
      switch (index) {
        case 0:
          return "Biblioteca Favorita";
        case 1:
          return "Repertório Favorito";
        case 2:
          return "Biblioteca";
        case 3:
          return "Repertório";
      }
    }

    if (temFavorita && !temRepertorioFavorito) {
      // Biblioteca Favorita + Biblioteca + Repertório
      switch (index) {
        case 0:
          return "Biblioteca Favorita";
        case 1:
          return "Biblioteca";
        case 2:
          return "Repertório";
      }
    }

    if (!temFavorita && temRepertorioFavorito) {
      // Repertório Favorito + Biblioteca + Repertório
      switch (index) {
        case 0:
          return "Repertório Favorito";
        case 1:
          return "Biblioteca";
        case 2:
          return "Repertório";
      }
    }

    // Caso base: só Biblioteca e Repertório
    return index == 0 ? "Biblioteca" : "Repertório";
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
}