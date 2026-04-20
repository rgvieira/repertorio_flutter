# check_flutter_env.ps1
# Verifica: Flutter, Android Studio, JDK, Gradle, variáveis de ambiente

$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n" [+] Verificando ambiente Flutter / Android [+]`n" -ForegroundColor Green

# --- 1. Flutter
Write-Host "[1] Flutter:" -ForegroundColor Yellow
$flutter = flutter --version 2>$null
if ($flutter) {
    $flutterVersion = ($flutter | Select-String "Flutter")[0].ToString()
    Write-Host "  ✅ Flutter instalado: $flutterVersion" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter NÃO encontrado no PATH" -ForegroundColor Red
}

# --- 2. Java / JDK
Write-Host "`n[2] JDK / Java:" -ForegroundColor Yellow
$java = java -version 2>&1 | Out-String
$javaHome = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "User")

if ($java -match "version") {
    Write-Host "  ✅ Java presente:" -ForegroundColor Green
    Write-Host "     $java".Trim() -ForegroundColor White
} else {
    Write-Host "  ❌ Java não detectado no PATH" -ForegroundColor Red
}

if ($javaHome) {
    Write-Host "  ✅ JAVA_HOME definido: $javaHome" -ForegroundColor Green
} else {
    Write-Host "  ❌ JAVA_HOME não definido" -ForegroundColor Red
}

# --- 3. Android Studio
Write-Host "`n[3] Android Studio:" -ForegroundColor Yellow
$studioDefault = "C:\Program Files\Android\Android Studio"
if (Test-Path $studioDefault) {
    Write-Host "  ✅ Android Studio encontrado em: $studioDefault" -ForegroundColor Green
} else {
    Write-Host "  ❌ Android Studio não encontrado em $studioDefault" -ForegroundColor Red

    # tenta pelo nome de processos
    $studioProc = Get-Process -Name "studio64" -ErrorAction SilentlyContinue
    if ($studioProc) {
        Write-Host "     ⚠️ Android Studio parece estar rodando, mas pasta não padrão." -ForegroundColor Yellow
    }
}

# --- 4. SDK / Flutter doctor
Write-Host "`n[4] flutter doctor (Android / SDK):" -ForegroundColor Yellow
$doctor = flutter doctor -v 2>&1 | Select-String "Android SDK", "Android Studio", "Android toolchain"
if ($doctor) {
    Write-Host "  ✅ flutter doctor OK (trechos relevantes):" -ForegroundColor Green
    $doctor | ForEach-Object { Write-Host "     $_" }
} else {
    Write-Host "  ⚠️ flutter doctor não retornou dados (pode ser falha de PATH ou licenças)" -ForegroundColor Yellow
}

# --- 5. Gradle (se estiver no PATH)
Write-Host "`n[5] Gradle:" -ForegroundColor Yellow
$gradle = gradle --version 2>$null
if ($gradle) {
    $gradleVersion = $gradle | Select-String "Gradle"
    Write-Host "  ✅ Gradle instalado:" -ForegroundColor Green
    $gradleVersion | ForEach-Object { Write-Host "     $_" }
} else {
    Write-Host "  ❌ Gradle não encontrado no PATH" -ForegroundColor Red
}

# --- 6. Variáveis de ambiente importantes
Write-Host "`n[6] Variáveis de ambiente importantes:" -ForegroundColor Yellow
$flutterHome = [System.Environment]::GetEnvironmentVariable("FLUTTER_ROOT", "User")
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($flutterHome) {
    Write-Host "  ✅ FLUTTER_ROOT definido: $flutterHome" -ForegroundColor Green
} else {
    Write-Host "  ❌ FLUTTER_ROOT não definido" -ForegroundColor Red
}

if ($path -match "flutter") {
    Write-Host "  ✅ Caminho Flutter aparece no PATH (ou pelo menos tem 'flutter' no texto)" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter não aparece no PATH" -ForegroundColor Red
}

Write-Host "`n[✓] Verificação finalizada.`n" -ForegroundColor Green
```

***

### Como usar

1. Salve como `check_flutter_env.ps1` em qualquer pasta.
2. No PowerShell, navegue até essa pasta e rode:
   ```powershell
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
   .\check_flutter_env.ps1
   ```
3. O script vai te mostrar:
   - Se Flutter, Java, Gradle e Android Studio estão no PATH.
   - Se `JAVA_HOME` e `FLUTTER_ROOT` estão definidos.
   - Um trecho de `flutter doctor` só pra ver o estado Android.

Se quiser, avisa:
- se você usa gradle local (`./gradlew`) ou só pelo PATH,
- se tá em Windows 10 ou 11,  
que eu adequo o script pra checar o `gradlew.bat` e caminhos específicos do seu setup.

xçxxxxxxxxxxxxxxxxxxxxxz
Win 11, Win 11 o. com detecção JDK e detecção do JDK do Android Studio,
verificação de android e sdkmanager no caminho,
e um “checklist” em texto puro pro teu setup Flutter + Android rodar de boa no Win

Vou entregar um script `.ps1` completo pra **Windows 11** que já faz:

- detecção de JDK,
- detecção do JDK embutido no Android Studio (`jbr` / `jre`),
- verificação de `android` e `sdkmanager` no caminho,
- e um checklist de texto puro no final mostrando o que tá OK ou faltando.

***

### Script completo: `check_flutter_android.ps1`

Salve esse conteúdo como `check_flutter_android.ps1` no Windows 11:

```powershell
# check_flutter_android.ps1
# Verifica: Flutter, Android Studio, JDK, SDK, sdkmanager, android, PATH, licenças (Win 11)

$ErrorActionPreference = "SilentlyContinue"

Write-Host "`n" [+] Verificando ambiente Flutter + Android - Windows 11 [+]`n" -ForegroundColor Green

### --- 1. Flutter
Write-Host "[1] Flutter:" -ForegroundColor Yellow
$flutter = flutter --version 2>$null
if ($flutter) {
    $flutterVersion = ($flutter | Select-String "Flutter")[0].ToString().Trim()
    Write-Host "  ✅ Flutter instalado: $flutterVersion" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter NÃO encontrado no PATH" -ForegroundColor Red
}

### --- 2. Java / JDK
Write-Host "`n[2] JDK / Java:" -ForegroundColor Yellow
$java = java -version 2>&1 | Out-String
$javaHomeUser = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "User")
$javaHomeMachine = [System.Environment]::GetEnvironmentVariable("JAVA_HOME", "Machine")

if ($java -match "version") {
    Write-Host "  ✅ Java presente:" -ForegroundColor Green
    Write-Host "     $java".Trim() -ForegroundColor White
} else {
    Write-Host "  ❌ Java não detectado no PATH" -ForegroundColor Red
}

if ($javaHomeUser) {
    Write-Host "  ✅ JAVA_HOME (User) definido: $javaHomeUser" -ForegroundColor Green
} else {
    Write-Host "  ❌ JAVA_HOME (User) não definido" -ForegroundColor Red
}

if ($javaHomeMachine) {
    Write-Host "  ✅ JAVA_HOME (Machine) definido: $javaHomeMachine" -ForegroundColor Green
}

### --- 3. JDK do Android Studio (jbr / jre)
Write-Host "`n[3] JDK do Android Studio:" -ForegroundColor Yellow
$studioJbr = "C:\Program Files\Android\Android Studio\jbr"
$studioJre = "C:\Program Files\Android\Android Studio\jre"

if (Test-Path $studioJbr) {
    Write-Host "  ✅ JDK do Android Studio (jbr) detectado: $studioJbr" -ForegroundColor Green
} elseif (Test-Path $studioJre) {
    Write-Host "  ✅ JDK do Android Studio (jre) detectado: $studioJre" -ForegroundColor Green
} else {
    Write-Host "  ❌ JDK do Android Studio (jbr/jre) não encontrado em C:\Program Files\Android\Android Studio" -ForegroundColor Red
}

### --- 4. Android Studio
Write-Host "`n[4] Android Studio:" -ForegroundColor Yellow
$studioDefault = "C:\Program Files\Android\Android Studio"
if (Test-Path $studioDefault) {
    Write-Host "  ✅ Android Studio encontrado em: $studioDefault" -ForegroundColor Green
} else {
    Write-Host "  ❌ Android Studio não encontrado em $studioDefault" -ForegroundColor Red
}

### --- 5. flutter doctor (Android / licenses)
Write-Host "`n[5] flutter doctor (Android / licenses):" -ForegroundColor Yellow
$doctor = flutter doctor -v 2>&1 | `
    Select-String "Android SDK", "Android Studio", "Android toolchain", "licenses"

if ($doctor) {
    Write-Host "  ✅ flutter doctor OK (trechos relevantes):" -ForegroundColor Green
    $doctor | ForEach-Object { Write-Host "     $_" }
} else {
    Write-Host "  ⚠️ flutter doctor não retornou dados (PATH/licenças?)" -ForegroundColor Yellow
}

### --- 6. Gradle
Write-Host "`n[6] Gradle:" -ForegroundColor Yellow
$gradle = gradle --version 2>$null
if ($gradle) {
    $gradleVersion = $gradle | Select-String "Gradle"
    Write-Host "  ✅ Gradle instalado no PATH:" -ForegroundColor Green
    $gradleVersion | ForEach-Object { Write-Host "     $_" }
} else {
    Write-Host "  ⚠️ Gradle não encontrado no PATH" -ForegroundColor Yellow
}

# Tenta achar gradlew.bat em locais típicos
Push-Location
$paths = ".\gradlew.bat", ".\android\gradlew.bat"
foreach ($p in $paths) {
    if (Test-Path $p) {
        Write-Host "     ✅ gradlew.bat encontrado: $p" -ForegroundColor Green
        break
    }
}
Pop-Location

### --- 7. android e sdkmanager
Write-Host "`n[7] android e sdkmanager:" -ForegroundColor Yellow

# de onde o Flutter costuma enxergar o SDK
$android = Get-Command "android.bat" -ErrorAction SilentlyContinue
$sdkmanager = Get-Command "sdkmanager.bat" -ErrorAction SilentlyContinue

if ($android) {
    Write-Host "  ✅ android.bat encontrado: $($android.Source)" -ForegroundColor Green
} else {
    Write-Host "  ❌ android.bat NÃO encontrado no PATH" -ForegroundColor Red
}

if ($sdkmanager) {
    Write-Host "  ✅ sdkmanager.bat encontrado: $($sdkmanager.Source)" -ForegroundColor Green
} elseif (Test-Path "$([System.Environment]::GetEnvironmentVariable('ANDROID_HOME'))\tools\bin\sdkmanager.bat") {
    Write-Host "  ⚠️ sdkmanager.bat existe no ANDROID_HOME, mas não está no PATH" -ForegroundColor Yellow
} else {
    Write-Host "  ❌ sdkmanager.bat NÃO encontrado em ANDROID_HOME\tools\bin"sdkmanager.bat`" nem no PATH" -ForegroundColor Red
}

### --- 8. ANDROID_HOME e FLUTTER_ROOT
Write-Host "`n[8] Variáveis ANDROID_HOME / FLUTTER_ROOT:" -ForegroundColor Yellow

$androidHome = [System.Environment]::GetEnvironmentVariable("ANDROID_HOME", "User")
$flutterHome = [System.Environment]::GetEnvironmentVariable("FLUTTER_ROOT", "User")
$path = [System.Environment]::GetEnvironmentVariable("Path", "User")

if ($androidHome) {
    Write-Host "  ✅ ANDROID_HOME definido: $androidHome" -ForegroundColor Green
} else {
    Write-Host "  ❌ ANDROID_HOME não definido" -ForegroundColor Red
}

if ($flutterHome) {
    Write-Host "  ✅ FLUTTER_ROOT definido: $flutterHome" -ForegroundColor Green
} else {
    Write-Host "  ❌ FLUTTER_ROOT não definido" -ForegroundColor Red
}

if ($path -match "flutter") {
    Write-Host "  ✅ Caminho Flutter aparece no PATH" -ForegroundColor Green
} else {
    Write-Host "  ❌ Flutter não aparece no PATH" -ForegroundColor Red
}

if ($path -match "Android") {
    Write-Host "  ✅ Caminho Android aparece no PATH (ou pelo menos tem 'Android' no texto)" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Caminho Android não aparece no PATH" -ForegroundColor Yellow
}

### --- 9. Checklist de texto puro em Windows 11
Write-Host "`n" [√] Checklist mínimo pra Flutter + Android rodar de boa no Windows 11:" -ForegroundColor Green
Write-Host "`n"

Write-Host "  [ ] 1. Flutter instalado e no PATH (flutter --version funciona)"
Write-Host "  [ ] 2. JDK >= 11 disponível (java -version OK)"
Write-Host "  [ ] 3. JAVA_HOME apontando para o JDK >= 11"
Write-Host "  [ ] 4. JDK do Android Studio (jbr/jre) existe em C:\Program Files\Android\Android Studio"
Write-Host "  [ ] 5. Android Studio instalado em C:\Program Files\Android\Android Studio"
Write-Host "  [ ] 6. flutter doctor sem erros de Android SDK e licenças"
Write-Host "  [ ] 7. Gradle ou gradlew.bat presente (PATH ou projeto Android)"
Write-Host "  [ ] 8. ANDROID_HOME apontando para a pasta do SDK"
Write-Host "  [ ] 9. android.bat e sdkmanager.bat acessíveis no PATH"
Write-Host "  [ ] 10. Variáveis FLUTTER_ROOT + PATH com os caminhos corretos"

Write-Host "`n[✓] Verificação finalizada no Windows 11.`n" -ForegroundColor Green
