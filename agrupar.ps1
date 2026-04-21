$projectName = (Get-Item .).Name
$outputFile = "$projectName.txt"
$files = Get-ChildItem -Path "lib" -Filter "*.dart" -Recurse

# Cria o arquivo e armazena a referência para pegar o caminho completo depois
$targetFile = New-Item -ItemType File -Path $outputFile -Force

foreach ($file in $files) {
    Add-Content -Path $outputFile -Value "`n// --- ARQUIVO: $($file.FullName) ---`n"
    Get-Content -Path $file.FullName | Add-Content -Path $outputFile
}

# Exibe o caminho completo do arquivo gerado
Write-Host "Concluído! O arquivo foi gerado em: $($targetFile.FullName)" -ForegroundColor Green

# execute como :
# powershell -ExecutionPolicy Bypass -File agrupar.ps1