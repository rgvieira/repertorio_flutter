import 'package:flutter/foundation.dart'; // ← ADICIONE
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

// Importes locais
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';
import 'package:repertorio_flutter/ads/rewarded_ad_service.dart';
import 'package:repertorio_flutter/pages/ajuda_page.dart';
import 'package:repertorio_flutter/pages/biblioteca_page.dart';
import 'package:repertorio_flutter/pages/busca_page.dart';
import 'package:repertorio_flutter/pages/configuracoes_page.dart';
import 'package:repertorio_flutter/pages/detalhes_pasta_page.dart';
import 'package:repertorio_flutter/pages/musicas_repertorio_page.dart';
import 'package:repertorio_flutter/pages/repertorio_page.dart';

Future<void> main() async {
  final WidgetsBinding binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  try {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox('minha_biblioteca'),
      Hive.openBox('settings'),
      Hive.openBox('config_pdf'),
    ]);

    // ✅ SÓ INICIALIZA ADS EM MOBILE (Android/iOS)
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      //  await BannerAdManager.initialize();
      await RewardedAdService.initialize();
    }
  } catch (e) {
    debugPrint('Erro na inicialização: $e');
  }

  runApp(const ScanPastasApp());
  FlutterNativeSplash.remove();
}

class ScanPastasApp extends StatelessWidget {
  const ScanPastasApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF005F97);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: _buildAppTheme(seedColor),
      home: const MainScreen(),
    );
  }

  ThemeData _buildAppTheme(Color seedColor) {
    const seedColor = Color(0xFF005F97);
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: ColorScheme.fromSeed(seedColor: seedColor).surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      fontFamily: 'Manrope',
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();
  BannerAdManager? _bannerAdManager; // ← Nullable
  RewardedAdService? _rewardedAdService; // ← Nullable

  @override
  void initState() {
    super.initState();
    // ✅ SÓ CRIA ADS EM MOBILE
    if (!kIsWeb) {
      _bannerAdManager = BannerAdManager();
      _rewardedAdService = RewardedAdService();
      _bannerAdManager!.loadBanner();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _bannerAdManager?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('minha_biblioteca').listenable(),
      builder: (context, Box box, _) {
        final tabConfig = _buildTabConfiguration(box);
        return DefaultTabController(
          length: tabConfig.tabs.length,
          child: Builder(
            builder: (context) {
              final tabController = DefaultTabController.of(context)!;
              return AnimatedBuilder(
                animation: tabController,
                builder: (context, _) {
                  return Scaffold(
                    appBar: _buildAppBar(tabController, tabConfig),
                    // ✅ SÓ MOSTRA BANNER EM MOBILE
                    bottomNavigationBar:
                        kIsWeb ? null : _bannerAdManager?.buildBannerWidget(),
                    body: TabBarView(children: tabConfig.pages),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  AppBar _buildAppBar(TabController tabController, TabConfiguration tabConfig) {
    return AppBar(
      title: Text(
        tabConfig.getTitle(tabController.index),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      actions: _buildAppBarActions(),
      bottom: TabBar(
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: tabConfig.tabs,
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: _navigateToSearch,
      ),
      IconButton(
        icon: const Icon(Icons.help_outline),
        onPressed: _navigateToHelp,
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: _navigateToSettings,
      ),
    ];
  }

  void _navigateToSearch() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const BuscaPage()));
  }

  void _navigateToHelp() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const AjudaPage()));
  }

  void _navigateToSettings() {
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => const ConfiguracoesPage()));
  }

  Map<String, dynamic>? _getRepertorioFavorito(Box box) {
    try {
      final result = box.values.firstWhere(
        (raw) {
          // Converte para Map<String, dynamic> explicitamente
          if (raw is! Map) return false;
          final map = Map<String, dynamic>.from(raw);
          return map['tipo'] == 'repertorio' &&
              map['favoritoRepertorio'] == true;
        },
        orElse: () => null, // ← Retorna null em vez de {}
      );

      // Se encontrou, converte para Map<String, dynamic>
      if (result != null && result is Map) {
        return Map<String, dynamic>.from(result);
      }
      return null;
    } catch (e) {
      debugPrint('Erro ao buscar repertório favorito: $e');
      return null;
    }
  }

  TabConfiguration _buildTabConfiguration(Box box) {
    final pastasRaiz = box.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e)) // ← Converte explicitamente
        .where((item) => item['tipo'] == 'root')
        .toList();

    final temFavorita = pastasRaiz.any((item) => item['favorita'] == true);
    final favoritoInfo = _getRepertorioFavorito(box);
    final temRepertorioFavorito =
        favoritoInfo != null; // ← Agora verifica null corretamente

    final tabs = <Tab>[];
    final pages = <Widget>[];

    if (temFavorita) {
      tabs.add(const Tab(
        icon: Stack(
          alignment: Alignment.topRight,
          children: [
            Icon(Icons.library_books),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.star, size: 12, color: Colors.amber),
            ),
          ],
        ),
        text: 'Biblioteca Favorita',
      ));
      pages.add(_buildBibliotecaFavorita(pastasRaiz));
    }

    if (temRepertorioFavorito) {
      tabs.add(const Tab(
        icon: Stack(
          alignment: Alignment.topRight,
          children: [
            Icon(Icons.music_note),
            Positioned(
              right: 0,
              top: 0,
              child: Icon(Icons.star, size: 12, color: Colors.amber),
            ),
          ],
        ),
        text: 'Repertório Favorito',
      ));
      pages.add(MusicasRepertorioPage(repertorioId: favoritoInfo!['_id']));
    }

    tabs.add(const Tab(
      icon: Icon(Icons.library_books),
      text: 'Biblioteca',
    ));
    pages.add(const BibliotecaPage());

    tabs.add(const Tab(
      icon: Icon(Icons.music_note),
      text: 'Repertório',
    ));
    pages.add(const RepertorioPage());

    return TabConfiguration(tabs: tabs, pages: pages);
  }

  Widget _buildBibliotecaFavorita(List<Map<String, dynamic>> pastasRaiz) {
    try {
      final pastaFav = pastasRaiz.firstWhere(
        (item) => item['favorita'] == true,
        orElse: () => <String, dynamic>{}, // ← Tipo explícito
      );

      if (pastaFav.isEmpty) {
        return const Center(child: Text("Nenhuma pasta raiz favoritada."));
      }

      return DetalhesPastaPage(
        rootPath: pastaFav['fullPath'].toString(),
        folderName: pastaFav['nome'].toString(),
        alwaysFlat: true,
      );
    } catch (e) {
      debugPrint('Erro ao buscar biblioteca favorita: $e');
      return const Center(child: Text("Erro ao carregar biblioteca favorita"));
    }
  }
}

class TabConfiguration {
  final List<Tab> tabs;
  final List<Widget> pages;

  TabConfiguration({required this.tabs, required this.pages});

  String getTitle(int index) {
    if (index >= tabs.length) return '';
    return tabs[index].text ?? '';
  }
}
