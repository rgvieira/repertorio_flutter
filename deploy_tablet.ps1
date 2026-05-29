# Script de Deploy para o dispositivo 2109119DG (b6fd1f9e)
$ErrorActionPreference = "Stop"

Write-Host "`n--- Iniciando Build para Repertório (arm64) ---" -ForegroundColor Cyan

# 1. Limpeza e Dependências
Write-Host "[1/3] Limpando e obtendo dependências..." -ForegroundColor Yellow
flutter clean
flutter pub get

# 2. Compilação focada na arquitetura do dispositivo
Write-Host "[2/3] Compilando APK Debug (android-arm64)..." -ForegroundColor Yellow
flutter build apk --debug --target-platform android-arm64 --split-per-abi
if ($LASTEXITCODE -ne 0) { Write-Error "ERRO: O build do Flutter falhou."; exit 1 }

# 3. Transferência via ADB
$DeviceID = "b6fd1f9e"
$ApkFolder = "build\app\outputs\flutter-apk"

# Localiza o APK específico gerado pelo build arm64
$ApkFile = Get-ChildItem -Path $ApkFolder -Filter "*arm64-v8a-debug.apk" | Select-Object -First 1
if ($null -eq $ApkFile) {
    $ApkFile = Get-ChildItem -Path $ApkFolder -Filter "app-debug.apk" | Select-Object -First 1
}

if ($null -eq $ApkFile) {
    Write-Error "ERRO: Nenhum APK foi encontrado em $ApkFolder."
    exit 1
}

$LocalPath = $ApkFile.FullName
$RemoteDir = "/storage/emulated/0/Download"
$RemoteFileName = "repertorio_debug.apk"

Write-Host "Localizado APK: $($ApkFile.Name)" -ForegroundColor Gray

Write-Host "[3/3] Enviando para o dispositivo $DeviceID..." -ForegroundColor Yellow

# 3.1 Instalação direta
adb -s $DeviceID install -r $LocalPath
if ($LASTEXITCODE -ne 0) { 
    Write-Host "AVISO: A instalação direta falhou. Verifique se 'Instalar via USB' está ativo." -ForegroundColor Yellow
}

# 3.2 Iniciar o App automaticamente
adb -s $DeviceID shell am start -n com.rgvieira63.repertorio/.MainActivity

# 3.3 Copiar para a memória interna (Download)
Write-Host "Copiando APK para a memória interna ($RemoteDir)..." -ForegroundColor Yellow
adb -s $DeviceID shell "mkdir -p $RemoteDir"
adb -s $DeviceID push $LocalPath "$RemoteDir/$RemoteFileName"
Write-Host "`nSucesso! App instalado e APK copiado para Download." -ForegroundColor Green