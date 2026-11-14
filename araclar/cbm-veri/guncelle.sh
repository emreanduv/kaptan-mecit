#!/usr/bin/env bash
# Kaptan Mecit kadrolarını Champion Battle Manager'ın haftalık türetilmiş dünyasından günceller (Klasik + Modern + VR aynı veri).
# Kullanım: guncelle.sh <emreanduv.github.io klonu (tam geçmişli)>
# KAYNAK dosyası en son aktarılan dunya.json'un Pages commit'ini tutar; kimlikler o dünyayla eşlenir (kayıtlar bozulmaz).
# Değişiklik yoksa 0 ile çıkar ve hiçbir şeye dokunmaz. Çıktı: "GUNCELLENDI <eski> <yeni>" ya da "AYNI".
set -euo pipefail
P="$1"; K="$(cd "$(dirname "$0")/../.." && pwd)"; C="$K/araclar/cbm-veri"
ESKI=$(cat "$C/KAYNAK"); YENI=$(git -C "$P" log -1 --format=%h -- veri/cbm/v1/dunya.json)
if [ "$(git -C "$P" rev-parse "$ESKI")" = "$(git -C "$P" rev-parse "$YENI")" ]; then echo "AYNI $YENI"; exit 0; fi
T=$(mktemp -d)
git -C "$P" show "$ESKI:veri/cbm/v1/dunya.json" > "$T/eski.json"
git -C "$P" show "$YENI:veri/cbm/v1/dunya.json" > "$T/yeni.json"
node "$C/km28.mjs" "$C/cbm-src" "$T/yeni.json" "$T/km28.json" - >&2
python3 "$C/km-yaz.py" "$T/km28.json" "$T/yeni.json" "$T/eski.json" "$P/veri/gercek-dunya/v1" "$K" >&2
node "$C/km3-takim.js" "$K" >&2
echo "$YENI" > "$C/KAYNAK"
echo "GUNCELLENDI $ESKI $YENI"
