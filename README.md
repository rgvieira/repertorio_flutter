# Repertório

Aplicativo Flutter para organizar, visualizar e anotar **partituras em PDF** — feito para músicos que precisam de uma biblioteca digital com suporte a repertórios personalizados.

## Funcionalidades

- **Galeria** — Aba inicial que exibe todos os arquivos indexados com filtro por nome, busca textual e paginação infinita (lazy loading via scroll)
- **Biblioteca de Pastas** — Adicione pastas do dispositivo, escaneie recursivamente com refresh, navegue em árvore ou busca flat
- **Visualizador de PDF** (pdfrx/Pdfium) com suporte a:
  - Navegação por teclado (setas, PgUp/PgDn, Espaço) e toque nas bordas (15% laterais)
  - **Modo noturno** — inverte as cores do PDF para leitura em ambientes escuros
  - **Paginação horizontal ou vertical** — configurável nas configurações
  - **Anotações** — caneta, marca-texto (com opacidade ajustável), borracha, linha, seta, círculo, texto e mover objetos
  - **Auto-salvamento** — traços e última página lembrados por documento (Hive)
  - **Impressão** com anotações (após anúncio recompensado)
- **Anotações por Arquivo** — Campo de texto + emoji picker ao lado de cada arquivo na lista
- **Busca Rápida** — Letra (Google) e Vídeo (YouTube) via links externos por arquivo
- **Repertórios (Playlists)** — Crie conjuntos de músicas, favorite um para acesso rápido como aba dinâmica
- **Busca Global** — Página dedicada para pesquisar por nome em toda a biblioteca indexada
- **Abas Dinâmicas** — Galeria completa e repertório favorito aparecem como abas na tela inicial (sem dependência de pasta raiz favorita)
- **Exportação/Importação** — Backup das configurações e anotações em JSON (pasta Download)
- **Política de Privacidade** — Multilíngue (PT, EN, ES, ZH) com link para configurações de anúncios
- **Anúncios Google AdMob** — Banner adaptativo e vídeo recompensado (apenas mobile)
- **Multiplataforma** — Android, iOS, Windows e Web (anúncios desativados na Web)

## Tecnologias

- **Flutter** 3.x (Dart 3.x) com Material Design 3
- **Hive** — banco NoSQL local (boxes: `minha_biblioteca`, `settings`, `config_pdf`)
- **pdfrx** — renderização de PDF (PDFium, grátis e open source)
- **Google Mobile Ads** — monetização (banner + rewarded)
- **File Picker** — seleção de pastas
- **Printing** — impressão com composição de anotações em PDF
- **url_launcher** — links para Google/YouTube
- **flutter_colorpicker** — seletor de cor para anotações
- **flutter_native_splash** — tela de splash nativa
- **flutter_launcher_icons** — ícone do app
- **Manrope** — fonte padrão do app

## Estrutura do Projeto

```
lib/
├── main.dart                       # Entrada, tema M3, navegação por abas + GaleriaContent (galeria completa com lazy loading)
├── ads/
│   ├── banner_ad_manager.dart      # Anúncio banner adaptativo
│   └── rewarded_ad_service.dart    # Anúncio recompensado (singleton)
├── services/
│   └── ad_config.dart              # Config remota de AdUnitIds via MethodChannel
├── widgets/
│   ├── file_list_item.dart         # StatefulWidget: tile reutilizável (anotação, emoji, repertório, letra, vídeo, visualizar)
│   └── emoji_picker.dart           # Seletor de emoji por categorias com busca
├── pages/
│   ├── splash_page.dart               # Splash animado com fade
│   ├── biblioteca_page.dart           # Gerenciamento de pastas raiz + scan recursivo
│   ├── busca_page.dart                # Busca global na biblioteca indexada
│   ├── detalhes_pasta_page.dart       # Navegação em árvore/flat com busca local
│   ├── repertorio_page.dart           # CRUD de repertórios + adicionar músicas
│   ├── musicas_repertorio_page.dart   # Músicas de um repertório
│   ├── visualizador_pdf_page.dart     # Visualizador PDF (pdfrx) + anotações (doodle) + impressão
│   ├── painter_overlay.dart           # Modelo Doodle + DrawingCanvas + MoveOverlay
│   ├── ajuda_page.dart                # Guia de uso do app
│   ├── configuracoes_page.dart        # Modo noturno, paginação H/V, backup JSON
│   └── privacy_policy_page.dart       # Política de privacidade multilíngue (PT/EN/ES/ZH)
```

## Hive Boxes

| Box | Finalidade |
|---|---|
| `minha_biblioteca` | Índice de pastas, arquivos, repertórios e configurações de favoritos |
| `settings` | Preferências (modo noturno, paginação) + anotações dos arquivos + desenhos dos PDFs |
| `config_pdf` | Última página lida por documento |

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

## Configuração de Anúncios

Os AdUnitIds de produção são fornecidos via MethodChannel (`com.rgvieira63.repertorio/ad_config`) do lado nativo. Em debug, o app usa IDs de teste automaticamente.

## Licença

Este projeto é privado. Todos os direitos reservados.
