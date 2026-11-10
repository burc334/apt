#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

repos=(
    AppDecrypt
    DPIBypass
    NightNight
    NotiFilter
    AlwaysShowEmojiKey
    CarrierHider
    HideBreadcrumbs
    CopyLogFix18
    SwipeSelectionReborn
    AirDropIPAFix
)

for repo in "${repos[@]}"; do
    echo "Downloading latest release: $repo"
    mkdir -p "$TMP/$repo"
    gh release download --repo "burc334/$repo" --dir "$TMP/$repo" --clobber --pattern "*.deb" --pattern "SHA256SUMS.txt"
    if command -v sha256sum >/dev/null 2>&1; then
        (cd "$TMP/$repo" && sha256sum -c SHA256SUMS.txt)
    else
        (cd "$TMP/$repo" && shasum -a 256 -c SHA256SUMS.txt)
    fi
done

rm -f "$ROOT"/docs/pool/*.deb
for repo in "${repos[@]}"; do
    cp "$TMP/$repo"/*.deb "$ROOT/docs/pool/"
done

"$ROOT/scripts/update-repo.sh"
