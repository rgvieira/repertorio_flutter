import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ConfiguracoesPage extends StatelessWidget {
  const ConfiguracoesPage({super.key});

  @override
  Widget build(BuildContext context) {
    var box = Hive.box('settings');

    return Scaffold(
      appBar: AppBar(
        title: const Text("Configurações"),
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box b, _) {
          return ListView(
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.dark_mode),
                title: const Text("Modo Noite"),
                subtitle: const Text("Inverter cores do PDF"),
                value: b.get('modoNoite', defaultValue: false),
                onChanged: (val) => b.put('modoNoite', val),
              ),
              SwitchListTile(
                secondary: const Icon(Icons.swap_horiz),
                title: const Text("Paginação Horizontal"),
                subtitle: const Text("Deslizar páginas para os lados"),
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
