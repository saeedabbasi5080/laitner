# Adds Myket Maven mirror to Flutter SDK's Gradle composite build.
# Run once after flutter upgrade if Android build cannot resolve Google Maven.

$ErrorActionPreference = 'Stop'

$localProps = Join-Path $PSScriptRoot '..\android\local.properties'
if (-not (Test-Path $localProps)) {
    Write-Error "android/local.properties not found. Run flutter pub get first."
}

$flutterSdk = (Get-Content $localProps | Where-Object { $_ -match '^flutter\.sdk=' }) -replace '^flutter\.sdk=', ''
$flutterSdk = $flutterSdk.Trim()
if (-not $flutterSdk -or -not (Test-Path $flutterSdk)) {
    Write-Error "Invalid flutter.sdk in local.properties: $flutterSdk"
}

$settingsFile = Join-Path $flutterSdk 'packages\flutter_tools\gradle\settings.gradle.kts'
if (-not (Test-Path $settingsFile)) {
    Write-Error "Flutter Gradle settings not found: $settingsFile"
}

$content = Get-Content $settingsFile -Raw

# Remove foreign repository fallbacks so sanctioned networks never attempt to
# contact Google, Maven Central, or the Gradle Plugin Portal.
$content = $content -replace '(?m)^\s*google\(\)\s*\r?\n?', ''
$content = $content -replace '(?m)^\s*mavenCentral\(\)\s*\r?\n?', ''
$content = $content -replace '(?m)^\s*gradlePluginPortal\(\)\s*\r?\n?', ''

if ($content -notmatch 'maven\.myket\.ir') {
    $content = $content -replace 'repositories \{', @'
repositories {
        maven { url = uri("https://maven.myket.ir/") }
'@
}

Set-Content -Path $settingsFile -Value $content -Encoding UTF8
Write-Host "Patched Flutter SDK Gradle settings:"
Write-Host $settingsFile
