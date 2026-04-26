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
        // Imagem ao lado do texto
        Image.asset(
          assetPath,
          width: 64,
          height: 64,
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Guia de Uso",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF186879),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSeccao("🎶 Apresentação", [
            _buildItemIcon(
              Icons.checklist,
              "",
              "Repertório exibe lista de arquivos PDF, de música, livros, arquigos, receitas, etc.",
            ),
            _buildItemIcon(
              Icons.checklist,
              "",
              "Copie o conteúdo para a pasta Documentos/Download/Books no celular ou tablet. Dúvidas sobre como copiar conteúdo, consulte Google.",
            ),
            _buildItemIcon(
              Icons.checklist,
              "",
              "1. Copie o conteúdo para a pasta Documentos/Download/Books no celular ou tablet. Dúvidas sobre como copiar conteúdo, consulte Google.",
            ),
            _buildItemComImagem(
              "Estrutura de pastas MPB",
              "Exemplo de organização da pasta raiz MPB.",
              "assets/imagens/pastas.png",
            ),
            // Exemplo de estrutura MPB
            _buildItemIcon(
              Icons.folder,
              "_Pasta raiz",
              "MPB",
            ),
            _buildItemIcon(
              Icons.folder,
              "__Subpasta",
              "Pasta A",
            ),
            _buildItemIcon(
              Icons.picture_as_pdf,
              "___Arquivo PDF",
              "arquivo 1.pdf",
            ),
            _buildItemIcon(
              Icons.folder,
              "__Subpasta",
              "Pasta B",
            ),
            _buildItemIcon(
              Icons.picture_as_pdf,
              "___Arquivo PDF",
              "arquivo 2.pdf",
            ),

            _buildItemIcon(
              Icons.checklist,
              "",
              "2. Em Bibliotecas, inclua a(s) pasta(s), marcando uma como favorita. "
                  "A biblioteca favorita será apresentada em tela propria.",
            ),
            _buildItemIcon(
              Icons.checklist,
              "",
              "3. Em Repertório, inclua repertório(s). Exemplo: Canções Natalinas.",
            ),

            _buildItemIcon(Icons.checklist, "",
                "4. No Repertório Favorito, apresentado após inclusão de pasta inicial, marcada como favorita, na lista apresentada, clique no primeiro ícone, após o nome, para incluir o arquivo em um repertório de sua preferência."),
          ]),
          _buildSeccao("📂 Telas Principais", [
            _buildItem(
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(Icons.library_books),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              "Biblioteca Favorita",
              "Exibe lista de arquivos da sua pasta principal, marcada com estrela.",
            ),
            _buildItem(
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Icon(Icons.music_note),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Icon(
                      Icons.star,
                      size: 12,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
              "Repertório Favorito",
              "Exibe lista de arquivos de seu repertório principal, marcado com estrela.",
            ),
            _buildItemIcon(
              Icons.library_books,
              "Biblioteca",
              "Gerencie suas pastas principais.",
            ),
            _buildItemIcon(
              Icons.music_note,
              "Repertório",
              "Crie listas personalizadas.",
            ),
          ]),
          _buildSeccao("📃 Conteúdo de Pasta(s)", [
            _buildItemIcon(
              Icons.music_note,
              "Favorita",
              "Exibe lista de arquivos da sua pasta principal, marcada com estrela.",
            ),
            _buildItemIcon(
              Icons.explicit,
              "Arquivo/Subpasta",
              "Nome do arquivo ou subpasta.",
            ),
            _buildItemIcon(
              Icons.lyrics,
              "Letra",
              "Link para busca de conteúdo.",
            ),
            _buildItemIcon(
              Icons.play_circle_fill,
              "Vídeo",
              "Link para busca de vídeos de conteúdo.",
            ),
          ]),
          const Divider(),
          _buildSeccao("🛠️ Ferramentas de Edição (PDF)", [
            _buildItemIcon(
              Icons.brush,
              "Modo Edição",
              "Ativa o painel lateral para desenhar ou escrever sobre a partitura.",
            ),
            _buildItemIcon(
              Icons.gesture,
              "Caneta",
              "Desenho livre para marcações rápidas.",
            ),
            _buildItemIcon(
              Icons.highlight,
              "Marca-texto",
              "Marca texto.",
            ),
            _buildItemIcon(
              Icons.auto_fix_normal,
              "Borracha",
              "Apaga desenhos.",
            ),
            _buildItemIcon(
              Icons.text_fields,
              "Expessura",
              "Define a expessura do desenho.",
            ),
            _buildItemIcon(
              Icons.remove,
              "Linha",
              "Desenha linha.",
            ),
            _buildItemIcon(
              Icons.trending_flat,
              "Seta",
              "Desenha seta.",
            ),
            _buildItemIcon(
              Icons.text_fields,
              "Texto",
              "Adiciona notas na página.",
            ),
            _buildItemIcon(
              Icons.drag_indicator,
              "Move",
              "Move um desenho.",
            ),
            _buildItemIcon(
              Icons.circle,
              "Cor",
              "Paleta de cores.",
            ),
            _buildItemIcon(
              Icons.delete_sweep,
              "Limpar Tudo",
              "Remove as anotações da página atual.",
            ),
          ]),
          const Divider(),
          _buildSeccao("⚙️ Configuração, Controle e Visualização", [
            _buildItemIcon(
              Icons.dark_mode,
              "Modo Noite/Dia",
              "Inverte cores de fundo do PDF, para facilitar a leitura.",
            ),
            _buildItemIcon(
              Icons.print,
              "Imprimir/Exportar",
              "Gera um novo arquivo PDF contendo todas as suas anotações.",
            ),
            _buildItemIcon(
              Icons.import_contacts,
              "Modo de Leitura",
              "Alterne entre rolagem vertical ou horizontal, em configurações.",
            ),
          ]),
          const Divider(),
          _buildSeccao("💡 Dicas Úteis", [
            _buildItemIcon(
              Icons.save,
              "Salvamento Automático",
              "Suas anotações são salvas no banco de dados assim que você termina o traço.",
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSeccao(String titulo, List<Widget> itens) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF186879),
            ),
          ),
        ),
        ...itens,
        const SizedBox(height: 10),
      ],
    );
  }

// 1) Versão genérica que recebe qualquer Widget como leading
  Widget _buildItem(Widget leading, String nome, String descricao) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: leading,
        title: nome.isEmpty
            ? null
            : Text(
                nome,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
        subtitle: Text(descricao),
      ),
    );
  }

// 2) Versão helper que recebe IconData e monta o Icon
  Widget _buildItemIcon(IconData icone, String nome, String descricao) {
    return _buildItem(
      Icon(icone, color: const Color(0xFF186879)),
      nome,
      descricao,
    );
  }
}
