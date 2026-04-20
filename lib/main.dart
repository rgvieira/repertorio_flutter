import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:scanpastas_flutter/pages/biblioteca_page.dart';
// Certifique-se de que o arquivo configuracoes_page.dart existe na pasta raiz ou ajuste o path
import 'package:scanpastas_flutter/pages/configuracoes_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  // Abrindo as duas caixas: a de dados e a de configurações
  await Hive.openBox('minha_biblioteca');
  await Hive.openBox('settings'); // ADICIONADO PARA AS CONFIGS

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

class _MainScreenState extends State<MainScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final String nomePrincipal = "Principal";

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Listener para atualizar o título quando deslizar as abas
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _tabController.index == 0
              ? nomePrincipal
              : _tabController.index == 1
                  ? "Repertório"
                  : "Biblioteca",
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          // BOTÃO DE CONFIGURAÇÃO ADICIONADO AQUI NO APPBAR PRINCIPAL
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const ConfiguracoesPage()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(icon: Icon(Icons.home), text: "Principal"),
            Tab(icon: Icon(Icons.music_note), text: "Repertório"),
            Tab(icon: Icon(Icons.library_books), text: "Biblioteca"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          Center(child: Text("Tela $nomePrincipal")),
          const Center(child: Text("Tela de Repertório")),
          const BibliotecaPage(),
        ],
      ),
    );
  }
}
