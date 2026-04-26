import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

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
            ],
          );
        },
      ),
    );
  }
}
