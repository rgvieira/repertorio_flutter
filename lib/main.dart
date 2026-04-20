import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:collection/collection.dart';

import 'package:scanpastas_flutter/pages/biblioteca_page.dart';
import 'package:scanpastas_flutter/pages/configuracoes_page.dart';
import 'package:scanpastas_flutter/pages/detalhes_pasta_page.dart';

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
      home: const DefaultTabController(
        length: 3,
        child: MainScreen(),
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final String nomePrincipal = "Principal";

  @override
  Widget build(BuildContext context) {
    final Box box = Hive.box('minha_biblioteca');

    final List<Map> pastasRaiz = box.values
        .where((item) => item is Map && item['tipo'] == 'root')
        .cast<Map>()
        .toList();

    final bool temFavorita =
        pastasRaiz.where((item) => item['favorita'] == true).isNotEmpty;

    // Título do AppBar
    String currentTitle =
        _getTitle(DefaultTabController.of(context)!.index, temFavorita);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          currentTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
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
          tabs: [
            if (temFavorita)
              const Tab(
                icon: Icon(Icons.home),
                text: "Favorita",
              ),
            const Tab(
              icon: Icon(Icons.library_books),
              text: "Biblioteca",
            ),
            const Tab(
              icon: Icon(Icons.music_note),
              text: "Repertório",
            ),
          ],
        ),
      ),
      body: TabBarView(
        children: [
          if (temFavorita) _buildTelaPrincipal(context, pastasRaiz),
          const Center(child: Text("Tela de Repertório")),
          const BibliotecaPage(),
        ],
      ),
    );
  }

  String _getTitle(int index, bool temFavorita) {
    if (temFavorita) {
      return index == 0
          ? nomePrincipal
          : (index == 1 ? "Repertório" : "Biblioteca");
    } else {
      return index == 0 ? "Repertório" : "Biblioteca";
    }
  }

  Widget _buildTelaPrincipal(BuildContext context, List<Map> pastasRaiz) {
    Map? pastaFav = null;
    for (final item in pastasRaiz) {
      if (item['favorita'] == true) {
        pastaFav = item;
        break;
      }
    }

    if (pastaFav == null) {
      return const Center(
        child: Text("Nenhuma pasta raiz favoritada."),
      );
    }

    // A partir daqui, o Dart ainda não "sabe" que pastaFav != null, então
    // forçamos o escopo com `final`
    final Map pasta = pastaFav;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Pasta Principal (Favorita)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder, color: Color(0xFF186879)),
              title: Text(
                pasta['nome'].toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                pasta['fullPath'].toString(),
                style: const TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DetalhesPastaPage(
                      rootPath: pasta['fullPath'].toString(),
                      folderName: pasta['nome'].toString(),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
