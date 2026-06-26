#!/bin/bash
# Clean zip for USB transfer — run from inside darcity folder.
set -e
cd "$(dirname "$0")/.."
OUT="${1:-darcity-for-boss.zip}"
zip -r "$OUT" darcity \
  -x "darcity/build/*" \
  -x "darcity/.dart_tool/*" \
  -x "darcity/android/.gradle/*" \
  -x "darcity/android/app/build/*" \
  -x "darcity/ios/Pods/*" \
  -x "darcity/linux/flutter/ephemeral/*" \
  -x "darcity/windows/flutter/ephemeral/*" \
  -x "darcity/macos/Flutter/ephemeral/*"
echo "Done: $(pwd)/$OUT"
echo "Copy that ONE file to the flash drive."
