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
if ($content -match 'maven\.myket\.ir') {
    Write-Host "Myket mirror already configured in Flutter SDK Gradle settings."
    exit 0
}

$newContent = $content -replace 'repositories \{', @'
repositories {
        maven { url = uri("https://maven.myket.ir/") }
'@

Set-Content -Path $settingsFile -Value $newContent -Encoding UTF8
Write-Host "Patched Flutter SDK Gradle settings:"
Write-Host $settingsFile
