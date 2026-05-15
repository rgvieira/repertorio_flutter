import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:repertorio_flutter/ads/banner_ad_manager.dart';

class AjudaPage extends StatefulWidget {
  const AjudaPage({super.key});

  @override
  State<AjudaPage> createState() => _AjudaPageState();
}

class _AjudaPageState extends State<AjudaPage> {
  final BannerAdManager _bannerManager1 = BannerAdManager();
  final BannerAdManager _bannerManager2 = BannerAdManager();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _bannerManager1.loadBanner(context);
        _bannerManager2.loadBanner(context);
      }
    });
  }

  @override
  void dispose() {
    _bannerManager1.dispose();
    _bannerManager2.dispose();
    super.dispose();
  }

  // 1) No pubspec.yaml, em flutter:
  // assets:
  //   - assets/imagens/mpb_exemplo.png

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Guia de Uso',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onPrimary, // casa com appBarTheme/primary
          ),
        ),
        // background/foreground vêm do appBarTheme (Material 3)
      ),
      bottomNavigationBar: null,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSeccao(
            context,
            '🎶 Apresentação',
            [
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                'Repertório exibe lista de arquivos PDF de música, livros, artigos, receitas, etc.',
              ),
              _buildItemIcon(
                context,
                Icons.account_tree_outlined,
                'Estrutura da pasta',
                'A pasta raiz tem de ter conteúdo em árvore. Pode conter arquivos e subpastas.',
                iconColor: Colors.amber,
              ),
              _buildItemIcon(
                context,
                Icons.check_outlined,
                '',
                '* Copie o conteúdo para a pastas Documentos, Download ou Books no celular ou tablet. Dúvidas sobre como copiar conteúdo, consulte Google.',
              ),
              _buildItemIcon(
                context,
                Icons.check_outlined,
                '',
                '* Em Biblioteca, inclua a(s) pasta(s). '
                    'Toda a coleção de arquivos será apresentada na própria tela de Biblioteca, bem como em Galeria. '
                    'Clique sobre uma pasta para ver seu conteúdo ou clique longo no nome do arquivo para ver a hierarquia.',
              ),
              _buildItemIcon(
                context,
                Icons.check_outlined,
                '',
                '* Em Repertórios, inclua repertório(s). Exemplo: Canções Natalinas.',
              ),
            ],
          ),
          _buildSeccao(
            context,
            '📂 Telas Principais',
            [
              _buildItem(
                context,
                Stack(
                  alignment: Alignment.topRight,
                  children: [Icon(Icons.photo_library, color: scheme.primary)],
                ),
                'Galeria',
                'Exibe lista de arquivos.',
              ),
              _buildItemIcon(
                context,
                Icons.account_tree_outlined,
                'Biblioteca',
                'Gerencie suas pastas principais. Clique longo no nome do arquivo para ver a hierarquia de pastas.',
                iconColor: Colors.amber,
              ),
              _buildItemIcon(
                context,
                Icons.music_note,
                'Repertório',
                'Acesso rápido ao repertório favorito.',
              ),
              _buildItemIcon(
                context,
                Icons.music_note,
                'Repertórios',
                'Crie listas, repertórios, personalizadas.',
              ),
            ],
          ),
          _buildSeccao(
            context,
            '📃 Conteúdo de Pasta(s)',
            [
              _buildItemIcon(
                context,
                Icons.music_note,
                'Adiciona ao repertório.',
                'Inclui o arqivo ao repertório marcado como favorito.',
              ),
              _buildItemIcon(
                context,
                Icons.emoji_emotions,
                'Emoji',
                'Lista de emojis.',
              ),
              _buildItemIcon(
                context,
                Icons.lyrics,
                'Letra',
                'Link para busca de conteúdo.',
              ),
              _buildItemIcon(
                context,
                Icons.play_circle_fill,
                'Vídeo',
                'Link para busca de vídeos de conteúdo.',
              ),
            ],
          ),
          const Divider(),
          _buildSeccao(
            context,
            '🛠️ Ferramentas de Edição (PDF)',
            [
              _buildItemIcon(
                context,
                Icons.brush,
                'Modo Edição',
                'Ativa o painel lateral para desenhar ou escrever sobre a partitura.',
              ),
              _buildItemIcon(
                context,
                Icons.gesture,
                'Caneta',
                'Desenho livre para marcações rápidas.',
              ),
              _buildItemIcon(
                context,
                Icons.highlight,
                'Marca-texto',
                'Marca texto.',
              ),
              _buildItemIcon(
                context,
                Icons.opacity,
                'Opacidade',
                'Escolhe opacidade do marca-texto.',
              ),
              _buildItemIcon(
                context,
                Icons.auto_fix_normal,
                'Borracha',
                'Apaga desenhos.',
              ),
              _buildItemIcon(
                context,
                Icons.text_fields,
                'Expessura',
                'Define a expessura do desenho.',
              ),
              _buildItemIcon(
                context,
                Icons.remove,
                'Linha',
                'Desenha linha.',
              ),
              _buildItemIcon(
                context,
                Icons.line_weight,
                'Expessura',
                'Escolhe expessura da linha.',
              ),
              _buildItemIcon(
                context,
                Icons.remove,
                'Linha',
                'Desenha linha.',
              ),
              _buildItemIcon(
                context,
                Icons.trending_flat,
                'Seta',
                'Desenha seta.',
              ),
              _buildItemIcon(
                context,
                Icons.text_fields,
                'Texto',
                'Adiciona notas na página.',
              ),
              _buildItemIcon(
                context,
                Icons.drag_indicator,
                'Move',
                'Move um desenho.',
              ),
              _buildItemIcon(
                context,
                Icons.circle,
                'Cor',
                'Paleta de cores.',
              ),
              _buildItemIcon(
                context,
                Icons.delete_sweep,
                'Limpar Tudo',
                'Remove as anotações da página atual.',
              ),
            ],
          ),
          const Divider(),
          _buildSeccao(
            context,
            '⚙️ Configuração, Controle e Visualização',
            [
              _buildItemIcon(
                context,
                Icons.dark_mode,
                'Modo Noite/Dia',
                'Inverte cores de fundo do PDF, para facilitar a leitura.',
              ),
              _buildItemIcon(
                context,
                Icons.touch_app,
                'Mostrar/Ocultar',
                'Mostra/Oculta itens na lista de arquivos (Anotações/Emoji/Repertório na Lista/Letra/Vídeo).',
              ),
              _buildItemIcon(
                context,
                Icons.print,
                'Imprimir/Exportar',
                'Gera um novo arquivo PDF contendo todas as suas anotações.',
              ),
              _buildItemIcon(
                context,
                Icons.import_contacts,
                'Modo de Leitura',
                'Alterne entre rolagem vertical ou horizontal, em configurações.',
              ),
            ],
          ),
          const Divider(),
          _buildSeccao(
            context,
            '💡 Dicas Úteis',
            [
              _buildItemIcon(
                context,
                Icons.save,
                'Salvamento Automático',
                'Suas anotações são salvas no banco de dados assim que você termina o traço.',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSeccao(BuildContext context, String titulo, List<Widget> itens) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            titulo,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: scheme.primary,
            ),
          ),
        ),
        ...itens,
        const SizedBox(height: 10),
      ],
    );
  }

  // 1) Versão genérica que recebe qualquer Widget como leading
  Widget _buildItem(
      BuildContext context, Widget leading, String nome, String descricao) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: nome.isEmpty
            ? null
            : Text(
                nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        subtitle: Text(
          descricao,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildItemIcon(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle, {
    Color? iconColor,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: iconColor ?? Theme.of(context).iconTheme.color,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
