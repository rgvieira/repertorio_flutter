# Repertório

Aplicativo Flutter para organizar, visualizar e anotar **partituras em PDF** — feito para músicos que precisam de uma biblioteca digital com suporte a repertórios personalizados.

## Funcionalidades

- **Galeria** — Aba dinâmica que aparece apenas quando há arquivos indexados. Exibe todos os arquivos com filtro por nome (mín. 3 caracteres, busca textual e por emoji/anotação), emoji picker inline no campo de busca e paginação infinita (lazy loading via scroll)
- **Biblioteca de Pastas** — Adicione pastas do dispositivo, escaneie recursivamente com refresh (sem duplicatas de fullPath), navegue em árvore ou busca flat. Clique longo no nome do arquivo para ver a hierarquia de pastas
- **Visualizador de PDF** (pdfx) com suporte a:
  - Renderização direta via pdfx (não depende do subsistema de impressão)
  - Navegação por teclado (setas, PgUp/PgDn, Espaço) e toque nas bordas (15% laterais)
  - **Modo noturno** — inverte as cores do PDF para leitura em ambientes escuros
  - **Anotações** — caneta, marca-texto (com opacidade ajustável), borracha, linha, seta, círculo, texto e mover objetos
  - **Auto-salvamento** — traços e última página lembrados por documento (Hive)
  - **Impressão** com anotações incorporadas em novo PDF (após anúncio recompensado)
- **Anotações por Arquivo** — Campo de texto + emoji picker ao lado de cada arquivo na lista (configurável individualmente)
- **Busca Rápida** — Letra (Google) e Vídeo (YouTube) via links externos por arquivo
- **Repertórios (Playlists)** — Crie conjuntos de músicas, favorite um para acesso rápido como aba dinâmica
- **Abas Dinâmicas** — Galeria, Biblioteca, Repertório Favorito e Repertórios
- **Controle Individual de Botões** — Em Configurações, liga/desliga cada botão da lista: anotação, emoji, repertório, letra e vídeo
- **Exportação/Importação** — Backup das configurações e anotações em JSON (pasta Download)
- **Política de Privacidade** — Multilíngue (PT, EN, ES, ZH) acessível via link no rodapé da página de Ajuda
- **Anúncios Google AdMob** — Banner adaptativo âncora (largura total, orientação dinâmica), vídeo recompensado (apenas mobile), toggle liga/desliga visível em todos os modos
- **Multiplataforma** — Android, iOS, Windows e Web (anúncios desativados na Web)

## Tecnologias

- **Flutter** 3.x (Dart 3.x) com Material Design 3
- **Hive** — banco NoSQL local (boxes: `minha_biblioteca`, `settings`, `config_pdf`)
- **pdfx** — renderização de PDF nativa (Android/iOS/Windows/Linux/Web)
- **pdf** + **printing** — geração de PDF com anotações para impressão
- **Google Mobile Ads** — monetização (banner adaptativo + rewarded)
- **File Picker** — seleção de pastas
- **url_launcher** — links para Google/YouTube
- **flutter_colorpicker** — seletor de cor para anotações
- **flutter_native_splash** — tela de splash nativa
- **flutter_launcher_icons** — ícone do app
- **Manrope** — fonte padrão do app

## Estrutura do Projeto

```
lib/
├── main.dart                       # Entrada, tema M3, navegação por abas + GaleriaContent (lazy loading, busca com emoji e anotação)
├── ads/
│   ├── banner_ad_manager.dart      # Banner adaptativo âncora com toggle via Hive e contexto
│   └── rewarded_ad_service.dart    # Anúncio recompensado (singleton)
├── services/
│   └── ad_config.dart              # Config remota de AdUnitIds via MethodChannel
├── widgets/
│   ├── file_list_item.dart         # Tile reutilizável com clique para abrir PDF, clique longo para hierarquia, botões individuais configuráveis + campo editável + emoji picker
│   └── emoji_picker.dart           # Seletor de emoji por categorias com busca
├── pages/
│   ├── splash_page.dart               # Splash animado com fade
│   ├── biblioteca_page.dart           # Gerenciamento de pastas + scan recursivo (sem dup fullPath) + hierarquia via clique longo
│   ├── busca_page.dart                # (não utilizado atualmente — busca global removida)
│   ├── detalhes_pasta_page.dart       # Navegação em árvore/flat com busca local
│   ├── repertorio_page.dart           # CRUD de repertórios + adicionar músicas
│   ├── musicas_repertorio_page.dart   # Músicas de um repertório com banner carregado via addPostFrameCallback
│   ├── visualizador_pdf_page.dart     # Visualizador PDF (pdfx) + anotações (doodle) + impressão
│   ├── painter_overlay.dart           # Modelo Doodle + DrawingCanvas + MoveOverlay
│   ├── ajuda_page.dart                # Guia de uso do app (com imagem responsiva, ícones coloridos, link privacidade)
│   ├── configuracoes_page.dart        # Noite, horizontal, botões individuais, anúncios, backup
│   └── privacy_policy_page.dart       # Política de privacidade multilíngue (PT/EN/ES/ZH)
```

## Hive Boxes

| Box | Finalidade |
|---|---|
| `minha_biblioteca` | Índice de pastas, arquivos (sem duplicatas de fullPath), repertórios e favoritos |
| `settings` | Preferências (modo noturno, paginação, botões, anúncios) + anotações (`item_ann_*`) + desenhos dos PDFs |
| `config_pdf` | Última página lida por documento |

## Configurações Disponíveis

| Configuração | Chave Hive | Padrão |
|---|---|---|
| Modo Noite | `modoNoite` | `false` |
| Paginação Horizontal | `horizontal` | `false` |
| Anotação na Lista | `mostrarAnotacao` | `true` |
| Emoji na Lista | `mostrarEmoji` | `true` |
| Repertório na Lista | `mostrarRepertorio` | `true` |
| Letra na Lista | `mostrarLetra` | `true` |
| Vídeo na Lista | `mostrarVideo` | `true` |
| Anúncios | `adsHabilitados` | `true` |

## Detalhes de Implementação

### Busca na Galeria
- Mínimo de **3 caracteres** para ativar o filtro
- Busca por **substring** em qualquer posição do nome do arquivo (`contains`)
- Também busca no **campo de anotação/emoji** associado ao arquivo (chave `item_ann_<fullPath>` no Hive)
- Botão de emoji picker integrado como `suffixIcon` no campo de busca

### Anúncios
- Banner adaptativo âncora carregado via `BannerAdManager.loadBanner(BuildContext)`
- Largura total (`double.infinity`) com altura adaptativa por orientação
- Todos os callers usam `addPostFrameCallback` para passar `context` do `initState`
- Toggle `adsHabilitados` visível em todos os modos (sem `kDebugMode`)

### PDF
- Renderização com `package:pdfx` (display) — `PdfPageImage.width/height` são nullable
- `PdfDocument` do `package:pdf` escondido via `hide` para evitar conflito com `pdfx`
- Impressão usa `package:printing` (funciona no fluxo de print)

## Como Executar

```bash
# Clone o repositório
git clone https://github.com/rgvieira/repertorio_flutter.git
cd repertorio_flutter

# Instale as dependências
flutter pub get

# Execute em desenvolvimento
flutter run -d chrome          # Web
flutter run -d windows         # Desktop Windows
flutter run                    # Android/iOS (dispositivo conectado)
```

## Build para Produção

```bash
# Android
flutter build apk --release --split-per-abi
flutter build appbundle --release

# iOS
flutter build ios --release

# Web
flutter build web --release

# Windows
flutter build windows --release
```

## Permissões

- **Android 11+** — solicita `MANAGE_EXTERNAL_STORAGE` na inicialização para acesso a arquivos via path direto
- **Android 10-** — solicita `READ_EXTERNAL_STORAGE` na inicialização
- A permissão é requisitada na função `main()` antes da abertura dos boxes Hive
- Se negada, o visualizador de PDF exibe erro ao tentar ler o arquivo; as demais funcionalidades continuam operando

## Configuração de Anúncios

Os AdUnitIds de produção são fornecidos via MethodChannel (`com.rgvieira63.repertorio/ad_config`) do lado nativo. Em debug, o app usa IDs de teste automaticamente. O banner é adaptativo âncora (ocupa a largura total da tela). É possível inibir/exibir banners via Configurações em qualquer modo.

## Licença

Este projeto é privado. Todos os direitos reservados.
