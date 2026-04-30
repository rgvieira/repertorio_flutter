import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

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

      // Caminho padrão da pasta Download no Android
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
            ],
          );
        },
      ),
    );
  }
}
