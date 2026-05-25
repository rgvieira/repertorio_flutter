# Script de Deploy PowerShell para Repertório
$ErrorActionPreference = "Stop"
$DeviceID = "b6fd1f9e"
$RemotePath = "/sdcard/Download/apk"
$ApkName = "repertorio-debug.apk"
$LocalApk = "build\app\outputs\flutter-apk\app-debug.apk"

Write-Host "[1/3] Compilando APK de Debug (arm64)..." -ForegroundColor Cyan
flutter build apk --debug --target-platform android-arm64

Write-Host "`n[2/3] Garantindo que a pasta existe no dispositivo $DeviceID..." -ForegroundColor Cyan
adb -s $DeviceID shell "mkdir -p $RemotePath"

Write-Host "`n[3/3] Enviando APK para $RemotePath/$ApkName..." -ForegroundColor Cyan
adb -s $DeviceID push $LocalApk "$RemotePath/$ApkName"

Write-Host "`n======================================================" -ForegroundColor Green
Write-Host "  SUCESSO! O app foi enviado para o seu tablet."
Write-Host "======================================================" -ForegroundColor Green

# Mantém a janela aberta se não estiver rodando no terminal do VS Code
if ($Host.Name -eq "ConsoleHost") {
    Read-Host "Pressione Enter para sair"
}