import 'package:flutter/material.dart';

class AjudaPage extends StatelessWidget {
  const AjudaPage({super.key});

  // 1) No pubspec.yaml, em flutter:
  // assets:
  //   - assets/imagens/mpb_exemplo.png

  Widget _buildItemComImagem(String titulo, String texto, String assetPath) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          assetPath,
          width: 128,
          height: 128,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (titulo.isNotEmpty)
                Text(
                  titulo,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              Text(texto),
            ],
          ),
        ),
      ],
    );
  }

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
                'Repertório exibe lista de arquivos PDF, de música, livros, arquigos, receitas, etc.',
              ),
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                'Copie o conteúdo para a pasta Documentos/Download/Books no celular ou tablet. Dúvidas sobre como copiar conteúdo, consulte Google.',
              ),
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                '1. Copie o conteúdo para a pasta Documentos/Download/Books no celular ou tablet. Dúvidas sobre como copiar conteúdo, consulte Google.',
              ),
              _buildItemComImagem(
                'Estrutura da pasta MPB',
                'Exemplo de organização.',
                'assets/images/pastas.png',
              ),
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                '2. Em Bibliotecas, inclua a(s) pasta(s), marcando uma como favorita. '
                    'A biblioteca favorita será apresentada em tela propria.',
              ),
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                '3. Em Repertório, inclua repertório(s). Exemplo: Canções Natalinas.',
              ),
              _buildItemIcon(
                context,
                Icons.checklist,
                '',
                '4. No Repertório Favorito, apresentado após inclusão de pasta inicial, marcada como favorita, na lista apresentada, clique no primeiro ícone, após o nome, para incluir o arquivo em um repertório de sua preferência.',
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
                  children: [
                    Icon(Icons.library_books, color: scheme.primary),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
                'Biblioteca Favorita',
                'Exibe lista de arquivos da sua pasta principal, marcada com estrela.',
              ),
              _buildItem(
                context,
                Stack(
                  alignment: Alignment.topRight,
                  children: [
                    Icon(Icons.music_note, color: scheme.primary),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Icon(
                        Icons.star,
                        size: 12,
                        color: scheme.tertiary,
                      ),
                    ),
                  ],
                ),
                'Repertório Favorito',
                'Exibe lista de arquivos de seu repertório principal, marcado com estrela.',
              ),
              _buildItemIcon(
                context,
                Icons.library_books,
                'Biblioteca',
                'Gerencie suas pastas principais.',
              ),
              _buildItemIcon(
                context,
                Icons.music_note,
                'Repertório',
                'Crie listas personalizadas.',
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
                'Favorita',
                'Exibe lista de arquivos da sua pasta principal, marcada com estrela.',
              ),
              _buildItemIcon(
                context,
                Icons.explicit,
                'Arquivo/Subpasta',
                'Nome do arquivo ou subpasta.',
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

  // 2) Versão helper que recebe IconData e monta o Icon
  Widget _buildItemIcon(
      BuildContext context, IconData icone, String nome, String descricao) {
    final scheme = Theme.of(context).colorScheme;

    return _buildItem(
      context,
      Icon(icone, color: scheme.primary),
      nome,
      descricao,
    );
  }
}
