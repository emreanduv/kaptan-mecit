#!/bin/bash
# Champion Battle Manager "Modern" maç görünümü: Kaptan Mecit 3 web derlemesini (CBM izleme modu ?cbm=1 dahil) hedef klasöre koyar.
# Kullanım: bash araclar/modern-al-champion.sh <hedef-www-klasörü>   → <hedef>/modern/
# Tek kaynak: emreanduv.github.io deposundaki kaptan-mecit-3/ (km3'ün her web derlemesi oraya gönderilir).
set -euo pipefail
H="${1:?hedef klasör}"
T=$(mktemp -d)
git clone -q --depth 1 --filter=blob:none --sparse https://github.com/emreanduv/emreanduv.github.io "$T/site"
git -C "$T/site" sparse-checkout set kaptan-mecit-3
rm -rf "$H/modern" && mkdir -p "$H/modern"
cp "$T/site/kaptan-mecit-3/"index.* "$H/modern/"
rm -rf "$T"
test -s "$H/modern/index.wasm" && test -s "$H/modern/index.pck"
grep -q "dis_mac" "$H/modern/index.pck" || { echo "UYARI: bu Kaptan Mecit 3 derlemesinde CBM izleme modu yok"; exit 1; }
ls -la "$H/modern"
