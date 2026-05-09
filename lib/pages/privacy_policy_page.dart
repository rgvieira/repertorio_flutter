import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class PrivacyPolicyPage extends StatefulWidget {
  const PrivacyPolicyPage({super.key});

  @override
  State<PrivacyPolicyPage> createState() => _PrivacyPolicyPageState();
}

class _PrivacyPolicyPageState extends State<PrivacyPolicyPage> {
  late String selectedLang;

  @override
  void initState() {
    super.initState();
    // Detecta o idioma do sistema (ex: 'pt', 'en', 'es', 'zh')
    final String systemLocale = PlatformDispatcher.instance.locale.languageCode;

    // Se o idioma do sistema for suportado, usa ele; caso contrário, usa inglês
    if (['pt', 'en', 'es', 'zh'].contains(systemLocale)) {
      selectedLang = systemLocale;
    } else {
      selectedLang = 'en';
    }
  }

  final Map<String, Map<String, String>> content = {
    'pt': {
      'title': 'Política de Privacidade - App Repertório',
      'date': 'Última atualização: 08 de maio de 2026',
      'intro':
          'O app Repertório facilita o acesso a partituras e documentos PDF organizados em pastas. Crie repertórios, faça anotações e gerencie sua biblioteca pessoal de forma simples.',
      'data':
          'Este aplicativo não acessa dados pessoais. Não coletamos, armazenamos ou transmitimos informações como nome, e-mail ou localização.',
      'files':
          'O app acessa apenas pastas e arquivos PDF autorizados pelo usuário. Todo o processamento é local.',
      'ads':
          'O acesso é gratuito com anúncios (Google AdMob). Dados não pessoais podem ser coletados por terceiros para anúncios personalizados.',
      'contact': 'rgvieira63@yahoo.com.br',
      'sec_intro': 'Introdução',
      'sec_data': 'Coleta de Dados',
      'sec_ads': 'Anúncios',
      'btn_ads': 'Configurações',
    },
    'en': {
      'title': 'Privacy Policy - Repertório App',
      'date': 'Last update: May 8, 2026',
      'intro':
          'The Repertório app provides easy access to sheet music and PDFs. Create repertoires, make annotations, and manage your personal library simply.',
      'data':
          'This app does not access personal data. We do not collect, store, or transmit information such as name, email, or location.',
      'files':
          'The app accesses only user-authorized PDF folders and files. All processing is local.',
      'ads':
          'Access is free with ads (Google AdMob). Non-personal data may be collected by third parties for personalized ads.',
      'contact': 'rgvieira63@yahoo.com.br',
      'sec_intro': 'Introduction',
      'sec_data': 'Data Collection',
      'sec_ads': 'Advertisements',
      'btn_ads': 'Settings',
    },
    'es': {
      'title': 'Política de Privacidad - App Repertório',
      'date': 'Última actualización: 08 de mayo de 2026',
      'intro':
          'La app Repertório facilita el acceso a partituras y PDFs. Crea repertorios, haz anotaciones y gestiona tu biblioteca personal de forma sencilla.',
      'data':
          'Esta aplicación no accede a datos personales. No recopilamos, almacenamos ni transmitimos información como nombre o ubicación.',
      'files':
          'La app accede solo a carpetas y archivos PDF autorizados por el usuario. Todo el proceso es local.',
      'ads':
          'El acceso es gratuito con anuncios (Google AdMob). Terceros pueden recopilar datos no personales para anuncios personalizados.',
      'contact': 'rgvieira63@yahoo.com.br',
      'sec_intro': 'Introducción',
      'sec_data': 'Recopilación de Datos',
      'sec_ads': 'Anuncios',
      'btn_ads': 'Configuración',
    },
    'zh': {
      'title': '隐私政策 - Repertório 应用',
      'date': '最后更新：2026年5月8日',
      'intro': 'Repertório 应用让您可以轻松访问乐谱和 PDF。创建曲目列表、添加注释并简单地管理您的个人库。',
      'data': '此应用不访问个人数据。我们不收集、存储或传输姓名、电子邮件或位置等信息。',
      'files': '该应用仅访问用户授权的 PDF 文件夹和文件。所有处理均在本地进行。',
      'ads': '免费访问，包含广告 (Google AdMob)。第三方可能会收集非个人数据用于个性化广告。',
      'contact': 'rgvieira63@yahoo.com.br',
      'sec_intro': '介绍',
      'sec_data': '数据收集',
      'sec_ads': '广告',
      'btn_ads': '设置',
    },
  };

  Future<void> _launchAdsURL() async {
    final url = Uri.parse('https://adssettings.google.com');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final langContent = content[selectedLang]!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(langContent['title']!),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Language / Idioma:',
                  style: theme.textTheme.labelLarge,
                ),
                DropdownButton<String>(
                  value: selectedLang,
                  onChanged: (value) => setState(() => selectedLang = value!),
                  items: ['pt', 'en', 'es', 'zh'].map((lang) {
                    return DropdownMenuItem(
                      value: lang,
                      child: Text(lang.toUpperCase(),
                          style: TextStyle(color: scheme.primary)),
                    );
                  }).toList(),
                ),
              ],
            ),
            const Divider(height: 32),
            Text(
              langContent['title']!,
              style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: scheme.primary),
            ),
            Text(langContent['date']!, style: theme.textTheme.bodySmall),
            const SizedBox(height: 24),
            _buildSection(langContent['sec_intro']!, langContent['intro']!),
            _buildSection(langContent['sec_data']!, langContent['data']!),
            _buildSection(langContent['sec_data']!, langContent['files']!),
            const SizedBox(height: 16),
            Card(
              color: scheme.surfaceContainerLow,
              child: ListTile(
                title: Text(langContent['sec_ads']!,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(langContent['ads']!),
                trailing: ElevatedButton(
                  onPressed: _launchAdsURL,
                  child: Text(langContent['btn_ads']!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text('Contato: ${langContent['contact']}',
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        Text(text, style: const TextStyle(fontSize: 15)),
      ]),
    );
  }
}
