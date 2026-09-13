#!/bin/zsh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DEST="${1:-$HOME/Desktop/Asistan.app}"
DERIVED="$ROOT/build/DerivedData"

echo "Release derleniyor…"
xcodebuild \
  -project "$ROOT/Asistan.xcodeproj" \
  -scheme Asistan \
  -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -derivedDataPath "$DERIVED" \
  ONLY_ACTIVE_ARCH=YES \
  ARCHS=arm64 \
  CODE_SIGNING_ALLOWED=NO \
  build

APP="$DERIVED/Build/Products/Release/Asistan.app"
if [[ ! -d "$APP" ]]; then
  echo "Derleme çıktısı bulunamadı: $APP" >&2
  exit 1
fi

rm -rf "$DEST"
cp -R "$APP" "$DEST"
codesign --force --deep --sign - "$DEST"
xattr -cr "$DEST" 2>/dev/null || true

echo "Kuruldu: $DEST"
echo "Masaüstündeki Asistan’a çift tıkla. İlk seferde sağ tık → Aç gerekebilir."
