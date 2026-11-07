#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DOCS="$ROOT/docs"
cd "$DOCS"

: "${APT_GPG_KEY_ID:=burc334@users.noreply.github.com}"
if [[ -z "${GNUPGHOME:-}" && -d "$HOME/.config/burc334-apt/gnupg" ]]; then
    export GNUPGHOME="$HOME/.config/burc334-apt/gnupg"
fi
if [[ -z "${APT_GPG_PASSPHRASE_FILE:-}" && -f "$HOME/.config/burc334-apt/passphrase" ]]; then
    export APT_GPG_PASSPHRASE_FILE="$HOME/.config/burc334-apt/passphrase"
fi

rm -f Packages Packages.gz Packages.xz Packages.zst Packages.bz2 Release Release.gpg InRelease

echo "Generating Packages..."
dpkg-scanpackages -m pool /dev/null > Packages.tmp
python3 - <<'PY'
from pathlib import Path
p = Path("Packages.tmp")
lines = []
for line in p.read_text().splitlines():
    if line.startswith("Sileodepiction:"):
        line = "SileoDepiction:" + line.split(":", 1)[1]
    lines.append(line)
p.write_text("\n".join(lines) + "\n")
PY
mv Packages.tmp Packages

gzip -9 -c Packages > Packages.gz
xz -9 -c Packages > Packages.xz
zstd -q -19 -c Packages > Packages.zst
bzip2 -9 -c Packages > Packages.bz2

echo "Generating Release..."
python3 - <<'PY'
from pathlib import Path
import hashlib
import email.utils

files = ["Packages", "Packages.gz", "Packages.xz", "Packages.zst", "Packages.bz2"]
algorithms = [
    ("MD5Sum", "md5"),
    ("SHA1", "sha1"),
    ("SHA256", "sha256"),
    ("SHA512", "sha512"),
]
text = [
    "Origin: burc334",
    "Label: burc334",
    "Suite: stable",
    "Version: 1.0",
    "Codename: ios",
    "Architectures: iphoneos-arm64 iphoneos-arm64e",
    "Components: main",
    "Description: Tweaks by burc334",
    f"Date: {email.utils.formatdate(usegmt=True)}",
]
for label, algorithm in algorithms:
    text.append(f"{label}:")
    for name in files:
        data = Path(name).read_bytes()
        digest = hashlib.new(algorithm, data).hexdigest()
        text.append(f" {digest} {len(data):16d} {name}")
Path("Release").write_text("\n".join(text) + "\n")
PY

if [[ -n "${APT_GPG_KEY_ID:-}" ]]; then
    echo "Signing Release..."
    GPG=(gpg --batch --yes --pinentry-mode loopback)
    if [[ -n "${APT_GPG_PASSPHRASE_FILE:-}" ]]; then
        GPG+=(--passphrase-file "$APT_GPG_PASSPHRASE_FILE")
    fi
    GPG+=(-u "$APT_GPG_KEY_ID")
    "${GPG[@]}" --armor --detach-sign --output Release.gpg Release
    "${GPG[@]}" --clearsign --output InRelease Release
    "${GPG[@]}" --armor --export "$APT_GPG_KEY_ID" > repo-public.key
else
    rm -f Release.gpg InRelease repo-public.key
fi

echo "Done."
