import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:repertorio_flutter/pages/privacy_policy_page.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  Future<void> _exportarDados(BuildContext context) async {
    try {
      final boxSettings = Hive.box('settings');
      final boxConfig = Hive.box('config_pdf');

      // Consolida os dados das boxes em um único Map
      final data = {
        'settings':
            boxSettings.toMap().map((k, v) => MapEntry(k.toString(), v)),
        'config_pdf':
            boxConfig.toMap().map((k, v) => MapEntry(k.toString(), v)),
      };

      final jsonString = jsonEncode(data);

      const path = '/storage/emulated/0/Download/repertorio_backup.json';
      final file = File(path);

      await file.writeAsString(jsonString);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Backup exportado para a pasta Download!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  Future<void> _importarDados(BuildContext context) async {
    try {
      const path = '/storage/emulated/0/Download/repertorio_backup.json';
      final file = File(path);

      if (!await file.exists()) {
        throw 'Arquivo "repertorio_backup.json" não encontrado na pasta Download.';
      }

      final jsonString = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(jsonString);

      // Restaura os dados para as respectivas boxes
      if (data.containsKey('settings')) {
        final box = Hive.box('settings');
        await box.putAll(Map<String, dynamic>.from(data['settings']));
      }

      if (data.containsKey('config_pdf')) {
        final box = Hive.box('config_pdf');
        await box.putAll(Map<String, dynamic>.from(data['config_pdf']));
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dados importados com sucesso!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao importar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('settings');
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        // deixa o AppBar usar o tema global (Material 3)
        // se quiser forçar a mesma cor 0xFF186879, faça isso no appBarTheme
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          return ListView(
            children: [
              SwitchListTile(
                secondary: Icon(Icons.dark_mode, color: scheme.primary),
                title: const Text('Modo Noite'),
                subtitle: Text(
                  'Inverter cores do PDF',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('modoNoite', defaultValue: false),
                onChanged: (val) => b.put('modoNoite', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.swap_horiz, color: scheme.primary),
                title: const Text('Paginação Horizontal'),
                subtitle: Text(
                  'Deslizar páginas para os lados',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('horizontal', defaultValue: false),
                onChanged: (val) => b.put('horizontal', val),
              ),
              const Divider(),
              SwitchListTile(
                secondary: Icon(Icons.touch_app, color: scheme.primary),
                title: const Text('Anotação na Lista'),
                subtitle: Text(
                  'Campo de texto para anotação rápida',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('mostrarAnotacao', defaultValue: true),
                onChanged: (val) => b.put('mostrarAnotacao', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.emoji_emotions, color: scheme.primary),
                title: const Text('Emoji na Lista'),
                subtitle: Text(
                  'Botão para inserir emoji na anotação',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('mostrarEmoji', defaultValue: true),
                onChanged: (val) => b.put('mostrarEmoji', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.music_note, color: scheme.tertiary),
                title: const Text('Repertório na Lista'),
                subtitle: Text(
                  'Botão para adicionar música ao repertório',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('mostrarRepertorio', defaultValue: true),
                onChanged: (val) => b.put('mostrarRepertorio', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.lyrics, color: scheme.secondary),
                title: const Text('Letra na Lista'),
                subtitle: Text(
                  'Botão para buscar letra da música',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('mostrarLetra', defaultValue: true),
                onChanged: (val) => b.put('mostrarLetra', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.play_circle_fill, color: scheme.error),
                title: const Text('Vídeo na Lista'),
                subtitle: Text(
                  'Botão para buscar vídeo no YouTube',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('mostrarVideo', defaultValue: true),
                onChanged: (val) => b.put('mostrarVideo', val),
              ),
              SwitchListTile(
                secondary: Icon(Icons.ads_click, color: scheme.primary),
                title: const Text('Anúncios'),
                subtitle: Text(
                  'Inibir/exibir banners',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                value: b.get('adsHabilitados', defaultValue: true),
                onChanged: (val) => b.put('adsHabilitados', val),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.upload_file, color: scheme.primary),
                title: const Text('Exportar Backup'),
                subtitle: const Text(
                    'Salva configurações e anotações na pasta Download'),
                onTap: () => _exportarDados(context),
              ),
              ListTile(
                leading:
                    Icon(Icons.download_for_offline, color: scheme.primary),
                title: const Text('Importar Backup'),
                subtitle: const Text(
                    'Restaura dados do arquivo repertorio_backup.json'),
                onTap: () => _importarDados(context),
              ),
              const Divider(),
              ListTile(
                leading: Icon(Icons.privacy_tip, color: scheme.primary),
                title: const Text('Política de Privacidade'),
                subtitle: const Text('Saiba como seus dados são protegidos'),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
