/* Steamworks köprüsü. steam_appid.txt'de gerçek AppID yoksa (ya da Steam açık değilse) sessizce devre dışı kalır. */
const fs = require('node:fs'), path = require('node:path');
let istemci = null, hata = null, appId = 0;
function idBul() {
  for (const p of [path.join(process.cwd(), 'steam_appid.txt'), path.join(path.dirname(process.execPath), 'steam_appid.txt'), path.join(__dirname, 'steam_appid.txt')]) {
    try { const n = parseInt(fs.readFileSync(p, 'utf8'), 10); if (n > 0) return n; } catch {}
  }
  return 0;
}
exports.baslat = () => {
  appId = idBul(); if (!appId) { hata = 'AppID yok'; return; }
  try { const sw = require('steamworks.js'); istemci = sw.init(appId); sw.electronEnableSteamOverlay?.(); }
  catch (e) { hata = String(e?.message || e); istemci = null; }
};
exports.durum = () => ({ aktif: !!istemci, appId, hata, ad: istemci?.localplayer?.getName?.() || null });
exports.basarim = ad => { try { if (!istemci) return false; return istemci.achievement.activate(String(ad)); } catch { return false; } };
