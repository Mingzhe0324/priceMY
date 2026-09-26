$ErrorActionPreference = 'Stop'
Set-Location (Join-Path $PSScriptRoot '../apps/mobile')
if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Install Flutter SDK and add flutter/bin to PATH, then reopen the terminal.'
}
if (-not (Test-Path 'android')) {
    flutter create --platforms=android,ios,web --org my.pricemy --project-name pricemy .
    if ($LASTEXITCODE -ne 0) { throw 'Flutter platform generation failed.' }
}
# Remove ONLY the Flutter template test; PriceMY has its own tests.
if (Test-Path 'test/widget_test.dart') {
    $TemplateTest = Get-Content 'test/widget_test.dart' -Raw
    if ($TemplateTest -match 'Counter increments smoke test') { Remove-Item 'test/widget_test.dart' }
}
flutter pub get
if ($LASTEXITCODE -ne 0) { throw 'Dependency resolution failed.' }
flutter analyze --no-fatal-infos
if ($LASTEXITCODE -ne 0) { throw 'Analysis failed; review the output above.' }
flutter test
if ($LASTEXITCODE -ne 0) { throw 'Tests failed; review the output above.' }
Write-Host 'Ready. Run: cd apps/mobile; flutter run -d chrome (or choose an Android device).'
