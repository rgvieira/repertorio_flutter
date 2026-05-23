import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:permission_handler/permission_handler.dart';

import 'package:repertorio_flutter/ads/banner_ad_manager.dart';
import 'package:repertorio_flutter/ads/rewarded_ad_service.dart';
import 'package:repertorio_flutter/pages/ajuda_page.dart';
import 'package:repertorio_flutter/pages/biblioteca_page.dart';
import 'package:repertorio_flutter/pages/configuracoes_page.dart';
import 'package:repertorio_flutter/pages/musicas_repertorio_page.dart';
import 'package:repertorio_flutter/pages/repertorio_page.dart';
import 'package:repertorio_flutter/pages/visualizador_pdf_page.dart';
import 'package:repertorio_flutter/widgets/emoji_picker.dart';
import 'package:repertorio_flutter/widgets/file_list_item.dart';

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

    await _solicitarPermissaoArmazenamento();

    // ✅ SÓ INICIALIZA ADS EM MOBILE (Android/iOS)
    if (!kIsWeb) {
      await MobileAds.instance.initialize();
      await BannerAdManager.initialize();
      await RewardedAdService.initialize();
    }
  } catch (e) {
    debugPrint('Erro na inicialização: $e');
  }

  runApp(const ScanPastasApp());

  final sucesso = await _copiarPdfsPadrao();

  if (sucesso) {
    print('PDFs padrão copiados com sucesso');
  }

  FlutterNativeSplash.remove();
}

Future<bool> _copiarPdfsPadrao() async {
  if (kIsWeb) return false;
  try {
    final settings = Hive.box('settings');
    final jaCopiados =
        settings.get('pdfs_padrao_inicial_copiados', defaultValue: false)
            as bool;

    final appDir = await getApplicationDocumentsDirectory();
    final pastaDestino = Directory(p.join(appDir.path, 'Demonstração'));
    final rootPath = pastaDestino.path;
    const pdfs = ['Ave Maria - Piano.pdf', 'Transferir Arquivos.pdf'];

    if (jaCopiados && await pastaDestino.exists()) {
      settings.put('pdfs_padrao_inicial_status', 'Já copiados');
      return true;
    }

    if (!await pastaDestino.exists()) {
      await pastaDestino.create(recursive: true);
    }

    for (final nome in pdfs) {
      final assetPath = 'assets/pdf/Demonstração/$nome';
      final destPath = p.join(rootPath, nome);
      if (!await File(destPath).exists()) {
        final bytes = await rootBundle.load(assetPath);
        await File(destPath).writeAsBytes(bytes.buffer.asUint8List());
      }
    }

    final biblioteca = Hive.box('minha_biblioteca');
    await biblioteca.put(rootPath, {
      'id': rootPath,
      'nome': 'Demonstração',
      'fullPath': rootPath,
      'tipo': 'root',
      'pai': 'os_root',
    });
    for (final nome in pdfs) {
      final filePath = p.join(rootPath, nome);
      await biblioteca.put(filePath, {
        'id': filePath,
        'nome': nome,
        'fullPath': filePath,
        'pai': rootPath,
        'root': rootPath,
        'tipo': 'file',
        'extensao': '.pdf',
      });
    }
    await settings.put('pdfs_padrao_inicial_copiados', true);
    settings.put('pdfs_padrao_inicial_status', 'Copiado com sucesso');
    return true;
  } catch (e) {
    Hive.box('settings').put('pdfs_padrao_inicial_erro', e.toString());
    return false;
  }
}

Future<void> _solicitarPermissaoArmazenamento() async {
  if (kIsWeb || !Platform.isAndroid) return;

  if (await Permission.manageExternalStorage.isGranted) {
    debugPrint('✅ Permissão MANAGE_EXTERNAL_STORAGE já concedida');
    return;
  }

  // Tenta READ_EXTERNAL_STORAGE primeiro (Android 10-)
  final readStatus = await Permission.storage.request();
  if (readStatus.isGranted) return;

  // Tenta MANAGE_EXTERNAL_STORAGE (Android 11+)
  final manageStatus = await Permission.manageExternalStorage.request();
  if (manageStatus.isGranted) return;

  // Se negado, abre configurações do app p/ usuário ativar manualmente
  debugPrint('⚠️ Permissão de armazenamento negada — abrindo configurações');
  await openAppSettings();
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
    // Use o parâmetro seedColor passado, ou defina o padrão se preferir.
    // Removi a constante interna para não dar conflito com o parâmetro.

    final colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      secondary: const Color(0xFFFFA000), // Tom dourado da pasta
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        scrolledUnderElevation: 2,
        backgroundColor: seedColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        // Uso do surfaceContainerLow conforme sua intenção no M3
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor:
            const Color(0xFFFFA000), // FAB em destaque com a cor da pasta
        foregroundColor: Colors.black,
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
    if (!kIsWeb) {
      _bannerAdManager = BannerAdManager();
      _rewardedAdService = RewardedAdService();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!kIsWeb) _bannerAdManager?.loadBanner(context);
      _mostrarStatusPdfs(context);
    });
  }

  void _mostrarStatusPdfs(BuildContext context, {int tentativa = 0}) {
    if (tentativa > 15) return;
    final settings = Hive.box('settings');
    final erro = settings.get('pdfs_padrao_inicial_erro') as String?;
    if (erro != null && erro.isNotEmpty) {
      settings.delete('pdfs_padrao_inicial_erro');
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Erro ao copiar PDFs'),
          content: SingleChildScrollView(child: Text(erro)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(_), child: const Text('OK'))
          ],
        ),
      );
      return;
    }
    final status = settings.get('pdfs_padrao_inicial_status') as String?;
    if (status != null) {
      settings.delete('pdfs_padrao_inicial_status');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status), duration: const Duration(seconds: 4)),
      );
      return;
    }
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _mostrarStatusPdfs(context, tentativa: tentativa + 1);
    });
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
        icon: const Icon(Icons.help_outline),
        onPressed: _navigateToHelp,
      ),
      IconButton(
        icon: const Icon(Icons.settings),
        onPressed: _navigateToSettings,
      ),
    ];
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
          final type = (map['type'] ?? map['tipo'])?.toString();
          return type == 'repertorio' && map['favoritoRepertorio'] == true;
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
        .map((e) => Map<String, dynamic>.from(e))
        .where((item) => item['tipo'] == 'root')
        .toList();

    final temArquivos = box.values.any((raw) {
      if (raw is! Map) return false;
      return Map<String, dynamic>.from(raw)['tipo'] == 'file';
    });

    final temFavorita = pastasRaiz.any((item) => item['favorita'] == true);
    final favoritoInfo = _getRepertorioFavorito(box);
    final temRepertorioFavorito = favoritoInfo != null;

    final tabs = <Tab>[];
    final pages = <Widget>[];

    if (temArquivos) {
      tabs.add(const Tab(
        icon: Icon(Icons.queue_music),
        text: 'Galeria',
      ));
      pages.add(_buildGaleriaCompleta(box));
    }

    tabs.add(const Tab(
      icon: Icon(
        Icons.account_tree_outlined,
        color: Colors.amber,
      ),
      text: 'Biblioteca',
    ));
    pages.add(const BibliotecaPage());

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
        text: 'Repertório',
      ));
      pages.add(MusicasRepertorioPage(repertorioId: favoritoInfo!['_id']));
    }

    tabs.add(const Tab(
      icon: Stack(
        children: [
          Icon(Icons.music_note),
          Positioned(
            left: 8,
            bottom: 0,
            child: Icon(Icons.music_note, size: 16),
          ),
        ],
      ),
      text: 'Repertório',
    ));
    pages.add(const RepertorioPage());

    return TabConfiguration(tabs: tabs, pages: pages);
  }

  Widget _buildGaleriaCompleta(Box box) {
    final rootIds = <String>{};
    for (final raw in box.values) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['tipo'] == 'root') {
        rootIds.add(map['id'].toString());
      }
    }

    if (rootIds.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma pasta cadastrada.\nVá em "Biblioteca" e adicione uma pasta.',
          textAlign: TextAlign.center,
        ),
      );
    }

    return _GaleriaContent(box: box, rootIds: rootIds);
  }
}

class _GaleriaContent extends StatefulWidget {
  final Box box;
  final Set<String> rootIds;

  const _GaleriaContent({required this.box, required this.rootIds});

  @override
  State<_GaleriaContent> createState() => _GaleriaContentState();
}

class _GaleriaContentState extends State<_GaleriaContent>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _filterCtrl = TextEditingController();
  final FocusNode _filterFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();
  String _filter = '';
  int _loadedCount = 0;
  static const int _pageSize = 60;

  List<Map<String, dynamic>> _allFiles = [];
  bool _needsRecompute = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadedCount = _pageSize;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreScrollPosition();
    });
  }

  @override
  void didUpdateWidget(_GaleriaContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    _needsRecompute = true;
  }

  @override
  void dispose() {
    _filterCtrl.dispose();
    _filterFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _restoreScrollPosition() {
    if (!mounted) return;
    if (_allFiles.isEmpty) {
      if (_needsRecompute) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScrollPosition());
      }
      return;
    }
    if (!_scrollCtrl.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScrollPosition());
      return;
    }
    final savedOffset =
        Hive.box('settings').get('last_galeria_offset', defaultValue: 0.0) as double;
    if (savedOffset <= 0) return;
    final maxExtent = _scrollCtrl.position.maxScrollExtent;
    if (savedOffset > maxExtent && _loadedCount < _allFiles.length) {
      setState(() => _loadedCount = _allFiles.length);
      WidgetsBinding.instance.addPostFrameCallback((_) => _restoreScrollPosition());
      return;
    }
    _scrollCtrl.jumpTo(savedOffset.clamp(0, _scrollCtrl.position.maxScrollExtent));
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 300) {
      setState(() {
        _loadedCount = (_loadedCount + _pageSize).clamp(0, _allFiles.length);
      });
    }
    if (_scrollCtrl.position.pixels > 0) {
      Hive.box('settings').put('last_galeria_offset', _scrollCtrl.position.pixels);
    }
  }

  List<Map<String, dynamic>> _computeAllFiles() {
    final result = <Map<String, dynamic>>[];
    for (final raw in widget.box.values) {
      if (raw is! Map) continue;
      final map = Map<String, dynamic>.from(raw);
      if (map['tipo'] != 'file') continue;
      final root = (map['root'] ?? '').toString();
      if (widget.rootIds.contains(root)) {
        result.add(map);
      }
    }
    result.sort((a, b) =>
        (a['nome'] ?? '').toString().compareTo((b['nome'] ?? '').toString()));
    return result;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_needsRecompute) {
      _allFiles = _computeAllFiles();
      _needsRecompute = false;
    }

    final lowerFilter = _filter.toLowerCase();
    final filtered = _filter.isEmpty || _filter.length < 3
        ? _allFiles
        : _allFiles.where((f) {
            final nome = p
                .basenameWithoutExtension((f['nome'] ?? '').toString())
                .toLowerCase();
            if (nome.contains(lowerFilter)) return true;
            final fullPath = f['fullPath']?.toString() ?? '';
            final annKey = 'item_ann_$fullPath';
            final ann =
                (Hive.box('settings').get(annKey, defaultValue: '') as String)
                    .toLowerCase();
            if (ann.contains(lowerFilter)) return true;
            return false;
          }).toList();

    // Reset loaded count if filter changed or total shrunk
    if (_loadedCount > filtered.length) {
      _loadedCount =
          (_pageSize > filtered.length) ? filtered.length : _pageSize;
    }

    if (_allFiles.isEmpty) {
      return const Center(
        child: Text(
          'Nenhum arquivo encontrado.\nVá em "Biblioteca" e atualize a pasta com o botão ↻.',
          textAlign: TextAlign.center,
        ),
      );
    }

    final displayList = filtered.take(_loadedCount).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
          child: TextField(
            controller: _filterCtrl,
            focusNode: _filterFocus,
            decoration: InputDecoration(
              hintText: 'Procurar',
              prefixIcon: const Icon(Icons.filter_list),
              suffixIcon: InkWell(
                onTap: () {
                  _filterFocus.unfocus();
                  showModalBottomSheet(
                    context: context,
                    builder: (_) => EmojiPickerSheet(
                      onSelected: (emoji) {
                        final text = _filterCtrl.text;
                        final sel = _filterCtrl.selection;
                        final pos = sel.isValid ? sel.baseOffset : text.length;
                        final clamped = pos.clamp(0, text.length);
                        _filterCtrl.text = text.substring(0, clamped) +
                            emoji +
                            text.substring(clamped);
                        _filterCtrl.selection = TextSelection.collapsed(
                            offset: clamped + emoji.length);
                        _filter = _filterCtrl.text;
                        _loadedCount = _pageSize;
                      },
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  margin: const EdgeInsets.only(right: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primaryContainer
                        .withAlpha(100),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.emoji_emotions,
                      size: 18,
                      color: Theme.of(context).colorScheme.onPrimaryContainer),
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            onChanged: (v) {
              setState(() {
                _filter = v;
                _loadedCount = _pageSize;
              });
            },
          ),
        ),
        if (_filter.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              '${filtered.length} arquivo(s) encontrado(s)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    _filter.isEmpty
                        ? 'Nenhum arquivo encontrado.'
                        : 'Nenhum arquivo corresponde a "$_filter".',
                  ),
                )
              : ListView.builder(
                  controller: _scrollCtrl,
                  itemCount: displayList.length +
                      (displayList.length < filtered.length ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= displayList.length) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    return FileListItem(
                      item: displayList[index],
                      onViewTap: () async {
                        final map = displayList[index];
                        final path = map['fullPath']?.toString();
                        if (path == null || path.isEmpty) return;

                        Hive.box('settings').put('last_galeria_file', path);

                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VisualizadorPdfPage(
                              filePath: path,
                              title: p.basenameWithoutExtension(
                                  (map['nome'] ?? '').toString()),
                            ),
                          ),
                        );

                        _filterCtrl.clear();
                        _filter = '';
                        await SystemChannels.textInput.invokeMethod('TextInput.hide');
                        if (mounted) _restoreScrollPosition();
                      },
                    );
                  },
                ),
        ),
      ],
    );
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
