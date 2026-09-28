#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../apps/mobile"
if [ ! -d android ]; then
  flutter create --platforms=android,ios --org my.pricemy --project-name pricemy .
fi
if [ -f test/widget_test.dart ] && grep -q 'Counter increments smoke test' test/widget_test.dart; then
  rm test/widget_test.dart
fi
python ../../scripts/configure_android.py
flutter pub get
flutter analyze --no-fatal-infos
flutter test
printf 'Ready. Run flutter run from apps/mobile.\n'
