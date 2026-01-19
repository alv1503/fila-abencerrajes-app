Write-Host "--- INICIANDO DESPLIEGUE AUTOMATICO ---" -ForegroundColor Green

# 1. Compilar Web
Write-Host "1/5 Compilando WEB..." -ForegroundColor Cyan
flutter build web --release
if ($LASTEXITCODE -ne 0) { Write-Error "Error en Web"; exit }

# 2. Compilar Android
Write-Host "2/5 Compilando ANDROID..." -ForegroundColor Cyan
flutter build apk --release
if ($LASTEXITCODE -ne 0) { Write-Error "Error en Android"; exit }

# 3. Limpiar carpeta Public
Write-Host "3/5 Limpiando carpeta public..." -ForegroundColor Yellow
$publicDir = "public"
if (Test-Path $publicDir) { 
    Remove-Item -Path "$publicDir\*" -Recurse -Force 
} else {
    New-Item -ItemType Directory -Path $publicDir
}

# 4. Copiar Archivos
Write-Host "4/5 Organizando archivos..." -ForegroundColor Yellow

# Copiar contenido Web
Copy-Item -Path "build\web\*" -Destination $publicDir -Recurse

# Copiar APK y renombrar
$apkSource = "build\app\outputs\flutter-apk\app-release.apk"
$apkDest = "$publicDir\abencerrajes.apk"

if (Test-Path $apkSource) {
    Copy-Item -Path $apkSource -Destination $apkDest
    Write-Host "APK copiado: abencerrajes.apk" -ForegroundColor Green
} else {
    Write-Error "NO SE ENCONTRO EL APK."
    exit
}

# 5. Desplegar a Firebase
Write-Host "5/5 Subiendo a Firebase..." -ForegroundColor Magenta
firebase deploy

Write-Host "--- LISTO ---" -ForegroundColor Green