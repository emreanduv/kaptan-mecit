#!/usr/bin/env bash
# Kafa Topu modu = Legend Heads (emreanduv/legend-heads, www/) oyununun kendisi. Legend Heads App Store'da ayrı uygulama
# olarak 4.3 spam reddi aldığı için (25 Kas 2026) Emre'nin kararıyla Kaptan Mecit'in içinde mod olarak yaşar.
# Güncellemek için: bash araclar/kafatopu-al.sh /yol/legend-heads   (oyun ?km=1 ile Kaptan Mecit kipine geçer)
set -euo pipefail
KAYNAK="${1:?legend-heads klasörü}"; HEDEF="$(cd "$(dirname "$0")/.." && pwd)/www/kafatopu"
rm -rf "$HEDEF" && mkdir -p "$HEDEF" && cp "$KAYNAK"/www/* "$HEDEF"/
echo "Kafa Topu güncellendi: $(grep -o "const SURUM='[^']*'" "$HEDEF/index.html")"
