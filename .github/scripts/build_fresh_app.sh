#!/usr/bin/env bash
# Builds a brand new Flutter app that depends on this plugin. A fresh app gets
# the defaults library users get (Swift Package Manager, current AGP), which the
# checked-in example app and unit tests do not exercise.
#
# Usage: build_fresh_app.sh ios true|false   (use Swift Package Manager or not)
#        build_fresh_app.sh android
set -euo pipefail

target="$1"
swiftpm="${2:-false}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
app_dir="$(mktemp -d)/ci_probe"

flutter create --platforms="$target" --project-name ci_probe "$app_dir"
cd "$app_dir"
flutter pub add flutter_bicubic_resize --path "$repo_root"
perl -0pi -e "s/^flutter:\n/flutter:\n  config:\n    enable-swift-package-manager: $swiftpm\n/m" pubspec.yaml

if [ "$target" = "ios" ]; then
  flutter build ios --simulator --debug
else
  flutter build apk --debug
fi
