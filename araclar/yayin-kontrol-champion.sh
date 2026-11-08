#!/usr/bin/env bash
# Champion Battle Manager yayın öncesi kontrol (CLAUDE.md "Yayın güvenliği").
# Kullanım: yayin-kontrol-champion.sh <dal> <sürüm> <www/index.html> <SON-SURUM dosyası>
# Champion'ın ana çizgisi bu depoda champion-4 dalıdır (main, Kaptan Mecit'in dalı); derleme yalnız oradan alınır.
set -u
DAL="$1"; SURUM="$2"; HTML="$3"; SON="$4"; HATA=0
hata() { echo "::error::$1"; HATA=1; }
[ "$DAL" = "champion-4" ] || hata "Champion derlemesi yalnız champion-4 dalından alınır (verilen: $DAL)"
[ -f "$HTML" ] || { echo "::error::$HTML yok"; exit 1; }
for k in "Bir Mr. Anduv! yapımıdır." "Nasıl Oynanır" "Rehberi baştan göster" "Puan ver" "Arkadaşına öner" "Bize yaz" "Verilerimi sil"; do
  grep -q "$k" "$HTML" || hata "Standart özellik eksik: \"$k\""
done
grep -q "\"$SURUM\"" "$HTML" || hata "Oyunun içindeki sürüm ($SURUM) derleme sürümüyle aynı değil"
if [ -f "$SON" ]; then
  ESKI=$(tr -d '[:space:]' < "$SON")
  EN=$(printf '%s\n%s\n' "$ESKI" "$SURUM" | sort -V | tail -1)
  [ "$EN" = "$SURUM" ] || hata "Sürüm geri gidiyor: $SURUM < yayınlanan $ESKI"
fi
# Türkçe yazı (iOS "ı") ve ◀ ▶ işaretleri — CLAUDE.md "Türkçe yazı ve iOS işaretleri"
python3 "$(dirname "$0")/turkce-yazi-kontrol.py" www || hata "Türkçe yazı / iOS işaret denetimi tutmadı"
[ $HATA = 0 ] && echo "Yayın öncesi kontrol tamam: $DAL · $SURUM" || exit 1
