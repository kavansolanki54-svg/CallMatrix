# CallMatrix APK Generation Script
# This script builds the Flutter release APK and copies it to the root APK directory.

$ErrorActionPreference = "Stop"

Write-Host "=============================================" -ForegroundColor Cyan
Write-Host "      Building CallMatrix Android APK        " -ForegroundColor Cyan
Write-Host "=============================================" -ForegroundColor Cyan

# 1. Resolve Paths
$WorkspaceRoot = $PSScriptRoot
$MobileAppDir = Join-Path $WorkspaceRoot "MobileApp"
$ApkOutputDir = Join-Path $WorkspaceRoot "APK"
$BuildApkPath = Join-Path $MobileAppDir "build\app\outputs\flutter-apk\app-release.apk"
$FinalApkPath = Join-Path $ApkOutputDir "CallMatrix.apk"

# 2. Check for MobileApp directory
if (-not (Test-Path $MobileAppDir)) {
    Write-Error "Error: MobileApp directory not found at $MobileAppDir!"
    exit 1
}

# 3. Navigate and Run Flutter Build
Write-Host "`n[1/4] Navigating to MobileApp directory..." -ForegroundColor Yellow
Push-Location $MobileAppDir

Write-Host "[2/4] Cleaning build artifacts & fetching dependencies..." -ForegroundColor Yellow
& flutter clean
& flutter pub get

Write-Host "[3/4] Compiling release APK (this might take a few minutes)..." -ForegroundColor Yellow
& flutter build apk --release --no-tree-shake-icons

Pop-Location

# 4. Copy to Destination
Write-Host "`n[4/4] Copying compiled APK to output directory..." -ForegroundColor Yellow
if (-not (Test-Path $ApkOutputDir)) {
    New-Item -ItemType Directory -Force -Path $ApkOutputDir | Out-Null
}

if (Test-Path $BuildApkPath) {
    Copy-Item -Path $BuildApkPath -Destination $FinalApkPath -Force
    Write-Host "`n=============================================" -ForegroundColor Green
    Write-Host " SUCCESS: CallMatrix APK built successfully!" -ForegroundColor Green
    Write-Host " Location: $FinalApkPath" -ForegroundColor Green
    Write-Host "=============================================" -ForegroundColor Green
} else {
    Write-Error "Error: Compiled APK not found at $BuildApkPath!"
    exit 1
}
