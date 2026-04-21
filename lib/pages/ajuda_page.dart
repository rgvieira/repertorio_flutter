import 'package:flutter/material.dart';

class AjudaPage extends StatelessWidget {
  const AjudaPage({super.key});

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
            _buildItem(
              Icons.checklist,
              "",
              "Repertório exibe lista de arquivos PDF, voltados para música.",
            ),
            _buildItem(
              Icons.checklist,
              "",
              "Em pasta(s), adicione arquivos e subpastas. "
                  "Copie para a pasta Documentos no celular/tablet. Dúvidas, vide Google.",
            ),

            // Exemplo de estrutura MPB
            _buildItem(
              Icons.folder,
              "_Pasta raiz",
              "MPB",
            ),
            _buildItem(
              Icons.folder,
              "__Subpasta",
              "Pasta A",
            ),
            _buildItem(
              Icons.picture_as_pdf,
              "___Arquivo PDF",
              "arquivo 1.pdf",
            ),
            _buildItem(
              Icons.folder,
              "__Subpasta",
              "Pasta B",
            ),
            _buildItem(
              Icons.picture_as_pdf,
              "___Arquivo PDF",
              "arquivo 2.pdf",
            ),

            _buildItem(
              Icons.checklist,
              "",
              "Em Bibliotecas, inclua pasta(s) no aparelho celular/tablet. "
                  "Marque uma como principal, ou favorita.",
            ),
            _buildItem(
              Icons.checklist,
              "",
              "Em Repertório, inclua lista de repertório(s). Exemplo: Canções Natalinas.",
            ),
            _buildItem(
              Icons.checklist,
              "_",
              "Em Favorita, após inclusão de pasta inicial, será exibida listagem "
                  "como o conteúdo da pasta principal.",
            ),
          ]),
          _buildSeccao("📂 Telas Principais", [
            _buildItem(
              Icons.home,
              "Favorita",
              "Exibe lista de arquivos da sua pasta principal marcada com estrela.",
            ),
            _buildItem(
              Icons.library_books,
              "Biblioteca",
              "Onde você gerencia suas pastas raízes e escaneia novos arquivos.",
            ),
            _buildItem(
              Icons.music_note,
              "Repertório",
              "Listas personalizadas de músicas que você criou para apresentações.",
            ),
          ]),
          _buildSeccao("📃 Conteúdo de Pasta(s)", [
            _buildItem(
              Icons.music_note,
              "Favorita",
              "Exibe lista de arquivos da sua pasta principal, marcada com estrela.",
            ),
            _buildItem(
              Icons.explicit,
              "Arquivo/Subpasta",
              "Nome do arquivo ou subpasta.",
            ),
            _buildItem(
              Icons.lyrics,
              "Letra",
              "Link para letra de música ou conteúdo.",
            ),
            _buildItem(
              Icons.play_circle_fill,
              "Vídeo",
              "Link para vídeos de músicas ou conteúdo.",
            ),
          ]),
          const Divider(),
          _buildSeccao("🛠️ Ferramentas de Edição (PDF)", [
            _buildItem(
              Icons.brush,
              "Modo Edição",
              "Ativa o painel lateral para desenhar ou escrever sobre a partitura.",
            ),
            _buildItem(
              Icons.gesture,
              "Caneta",
              "Desenho livre para marcações rápidas.",
            ),
            _buildItem(
              Icons.highlight,
              "Marca-texto",
              "Cria traços semitransparentes para destacar partes da música.",
            ),
            _buildItem(
              Icons.text_fields,
              "Texto",
              "Adiciona notas escritas em pontos específicos da página.",
            ),
            _buildItem(
              Icons.auto_fix_normal,
              "Borracha",
              "Apaga desenhos específicos ao tocar neles.",
            ),
            _buildItem(
              Icons.delete_sweep,
              "Limpar Tudo",
              "Remove todas as anotações da página atual de uma vez.",
            ),
          ]),
          const Divider(),
          _buildSeccao("⚙️ Configuração, Controle e Visualização", [
            _buildItem(
              Icons.dark_mode,
              "Modo Noite/Dia",
              "Inverte cores de fundo do PDF, para facilitar a leitura.",
            ),
            _buildItem(
              Icons.swap_horiz,
              "Paginação",
              "Define a direção da paginação do PDF.",
            ),
            _buildItem(
              Icons.print,
              "Imprimir/Exportar",
              "Gera um novo arquivo PDF contendo todas as suas anotações.",
            ),
            _buildItem(
              Icons.palette,
              "Cor Ativa",
              "Altera a cor da caneta, formas e textos das suas marcações.",
            ),
            _buildItem(
              Icons.import_contacts,
              "Modo de Leitura",
              "Alterne entre rolagem vertical ou horizontal (página única) nas configurações.",
            ),
            _buildItem(
              Icons.dark_mode,
              "Modo Noite",
              "Inverte as cores do PDF para facilitar a leitura em ambientes escuros.",
            ),
          ]),
          const Divider(),
          _buildSeccao("💡 Dicas Úteis", [
            _buildItem(
              Icons.save,
              "Salvamento Automático",
              "Suas anotações são salvas no banco de dados assim que você termina o traço.",
            ),
            _buildItem(
              Icons.zoom_out_map,
              "Navegação",
              "Use as setas na barra inferior para trocar de página rapidamente.",
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

  Widget _buildItem(IconData icone, String nome, String descricao) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icone, color: const Color(0xFF186879)),
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
}
