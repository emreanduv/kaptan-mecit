/* CI duman testi: paketlenmiş Linux derlemesini açar, menüden kariyer başlatır, ekran görüntüsü alır. */
import { _electron } from 'playwright';
import fs from 'node:fs';
const exe = process.argv[2], cik = process.argv[3] || 'duman'; fs.mkdirSync(cik, { recursive: true });
const app = await _electron.launch({ executablePath: exe, args: ['--no-sandbox'] });
const p = await app.firstWindow(); const h = []; p.on('pageerror', e => h.push(e.message));
await p.setViewportSize?.({ width: 1600, height: 900 }).catch(() => {});
await p.waitForTimeout(5000);
const foto = async n => { await p.waitForTimeout(600); await p.screenshot({ path: `${cik}/${n}.png` }); };
await p.click('[data-act="dilSec"][data-v="en"]').catch(() => {}); await p.waitForTimeout(3000);   // ilk açılış: dil seçimi
await p.click('[data-act="mdKapat"]').catch(() => {});
await foto('1-menu');
await p.click('[data-act="yeniMod"][data-v="serbest"]'); await p.waitForTimeout(3000);
const tr = await p.$$('[data-act="yeniKulup"]'); await tr[1].click(); await p.fill('#menajerAd', 'Mr. Anduv'); await p.click('[data-act="baslat"]'); await p.waitForTimeout(2000);
await p.click('[data-act="mdKapat"]').catch(() => {});
await foto('2-genel');
await p.keyboard.press('3'); await foto('3-kadro');
const masaustu = await p.evaluate(() => !!window.cbmMasaustu && document.documentElement.classList.contains('ms-on'));
const otoSayac = await p.evaluate(() => !!document.querySelector('.devam .oto-sn'));
fs.writeFileSync(`${cik}/sonuc.json`, JSON.stringify({ masaustu, otoSayac, hatalar: h, steam: await p.evaluate(() => window.cbmMasaustu?.steam?.()) }, null, 1));
console.log('masaüstü:', masaustu, 'hatalar:', h);
await app.close();
