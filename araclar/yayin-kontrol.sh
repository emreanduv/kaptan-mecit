#!/usr/bin/env bash
# Kaptan Mecit yayın öncesi kontrol (CLAUDE.md "Yayın güvenliği").
# Kullanım: yayin-kontrol.sh <dal> <sürüm> <SON-SURUM dosyası>
# Uygulamanın ana ekranı açılış (www/index.html) + Klasik (www/klasik/index.html); standart özellikler Klasik'te.
set -u
DAL="$1"; SURUM="$2"; SON="$3"; HATA=0
hata() { echo "::error::$1"; HATA=1; }
[ "$DAL" = "main" ] || hata "Kaptan Mecit derlemesi yalnız main dalından alınır (verilen: $DAL)"
grep -q "Bir Mr. Anduv! yapımıdır." www/index.html || hata "Açılış ekranında \"Bir Mr. Anduv! yapımıdır.\" yok"
K=www/klasik/index.html
for k in "Bir Mr. Anduv! yapımıdır." "NASIL OYNANIR" "REHBERİ BAŞTAN GÖSTER" "PUAN VER" "ARKADAŞINA ÖNER" "BİZE YAZ" "VERİLERİMİ SİL"; do
  grep -qi "$k" "$K" || hata "Standart özellik eksik (Klasik): \"$k\""
done
grep -q "KM_SURUM='$SURUM'" "$K" || hata "Oyunun içindeki sürüm (KM_SURUM) derleme sürümü $SURUM ile aynı değil"
grep -q "\"version\": \"$SURUM\"" package.json || hata "package.json sürümü $SURUM değil"
if [ -f "$SON" ]; then
  ESKI=$(tr -d '[:space:]' < "$SON")
  EN=$(printf '%s\n%s\n' "$ESKI" "$SURUM" | sort -V | tail -1)
  [ "$EN" = "$SURUM" ] || hata "Sürüm geri gidiyor: $SURUM < yayınlanan $ESKI"
fi
# Türkçe yazı (iOS "ı") ve ◀ ▶ işaretleri — CLAUDE.md "Türkçe yazı ve iOS işaretleri"
python3 araclar/turkce-yazi-kontrol.py || hata "Türkçe yazı / iOS işaret denetimi tutmadı"
[ $HATA = 0 ] && echo "Yayın öncesi kontrol tamam: $DAL · $SURUM" || exit 1
