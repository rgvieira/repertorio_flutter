# Repertório

Aplicativo Flutter para organizar, visualizar e anotar **partituras em PDF** — feito para músicos que precisam de uma biblioteca digital de partituras com suporte a repertórios personalizados.

## Funcionalidades

- **Biblioteca de Pastas** — Adicione pastas do dispositivo, escaneie recursivamente e navegue em árvore ou busca plana
- **Visualizador de PDF** com suporte a:
  - Navegação por teclado (setas, PgUp/PgDn, Espaço) e toque nas bordas
  - **Modo noturno** — inverte as cores do PDF para leitura em ambientes escuros
  - **Paginação horizontal ou vertical** — configurável
  - **Anotações** — caneta, marcador, linha, seta, círculo, texto e borracha
  - **Auto-salvamento** — traços e páginas lembrados por documento
  - **Impressão** com anotações (após anúncio recompensado)
- **Repertórios (Playlists)** — Crie conjuntos de músicas, favorite um para acesso rápido
- **Busca Global** — Pesquise por nome em toda a biblioteca indexada
- **Favoritos** — Pastas raiz e repertórios favoritos aparecem como abas dinâmicas na tela inicial
- **Exportação/Importação** — Backup das configurações em JSON
- **Anúncios Google AdMob** — Banner adaptativo e vídeo recompensado (apenas mobile)
- **Multiplataforma** — Android, iOS, Windows e Web (anúncios desativados na Web)

## Capturas de Tela

| Biblioteca | Visualizador PDF | Anotações |
|---|---|---|
| *(em breve)* | *(em breve)* | *(em breve)* |

## Tecnologias

- **Flutter** 3.x (Dart 3.x)
- **Hive** — banco NoSQL local
- **Syncfusion Flutter PDF Viewer** — renderização de PDF
- **Google Mobile Ads** — monetização (banner + rewarded)
- **File Picker** — seleção de pastas
- **Path Provider** — diretórios do sistema
- **Printing** — impressão com composição de anotações
- **flutter_native_splash** — tela de splash nativa
- **flutter_launcher_icons** — ícone do app

## Estrutura do Projeto

```
lib/
├── main.dart                  # Entrada, tema, navegação por abas
├── ads/
│   ├── banner_ad_manager.dart  # Anúncio banner adaptativo
│   └── rewarded_ad_service.dart # Anúncio recompensado (singleton)
├── services/
│   └── ad_config.dart          # Config remota de AdUnitIds
├── widgets/
│   └── file_list_item.dart     # Tile reutilizável para arquivo/pasta
├── pages/
│   ├── splash_page.dart            # Splash animado
│   ├── biblioteca_page.dart        # Biblioteca de pastas
│   ├── busca_page.dart             # Busca global
│   ├── detalhes_pasta_page.dart    # Navegação em árvore/plana
│   ├── repertorio_page.dart        # CRUD de repertórios
│   ├── musicas_repertorio_page.dart # Músicas de um repertório
│   ├── visualizador_pdf_page.dart  # Visualizador PDF + anotações
│   ├── painter_overlay.dart        # Modelo Doodle + Canvas de desenho
│   ├── ajuda_page.dart             # Ajuda/guia do app
│   ├── configuracoes_page.dart     # Configurações + backup
│   └── privacy_policy_page.dart    # Política de privacidade multilíngue
├── database/                  # (reservado — Hive usado in-line)
└── models/                    # (reservado — Doodle definido em painter_overlay.dart)
```

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
