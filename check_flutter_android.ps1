Write-Host "=== Checando ambiente Flutter/Android ===" -ForegroundColor Cyan

# Verifica se JAVA_HOME está definido
if ($env:JAVA_HOME) {
    Write-Host "[OK] JAVA_HOME = $env:JAVA_HOME" -ForegroundColor Green
} else {
    Write-Host "[ERRO] JAVA_HOME não está definido" -ForegroundColor Red
}

# Verifica se FLUTTER_ROOT está definido
if ($env:FLUTTER_ROOT) {
    Write-Host "[OK] FLUTTER_ROOT = $env:FLUTTER_ROOT" -ForegroundColor Green
} else {
    Write-Host "[ERRO] FLUTTER_ROOT não está definido" -ForegroundColor Red
}

# Verifica se Gradle está disponível
$gradle = Get-Command gradle -ErrorAction SilentlyContinue
if ($gradle) {
    Write-Host "[OK] Gradle encontrado em PATH" -ForegroundColor Green
} else {
    Write-Host "[ERRO] Gradle não encontrado no PATH" -ForegroundColor Red
}

# Verifica se Flutter está disponível
$flutter = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutter) {
    Write-Host "[OK] Flutter encontrado em PATH" -ForegroundColor Green
} else {
    Write-Host "[ERRO] Flutter não encontrado no PATH" -ForegroundColor Red
}

# Executa flutter doctor para mostrar status
Write-Host "`n=== Resultado do flutter doctor ===" -ForegroundColor Yellow
flutter doctor
