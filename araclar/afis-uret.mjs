// Çizim Planı F3 (KM3): ortak afiş çizicisi www/pano.js ile 3B stadyum LED panolarının dokularını üretir.
// Kaynak km3/veri/takimlar.json → "afisler"; çıktı km3/veri/afis/<sıra>_<tr|en>.webp (pano 8 m × 0.95 m → 168×20 mantıksal, 6x).
// Çalıştır (depo kökünden): node araclar/afis-uret.mjs   (Playwright + Chromium gerekir)
// Afiş listesi değişince yeniden çalıştır; Godot --import .import dosyalarını kendisi yazar (yoksa CI'daki --import).
import { createRequire } from 'module';
const { chromium } = createRequire(import.meta.url)('playwright');
import fs from 'fs'; import path from 'path';
const kok = path.resolve(path.dirname(new URL(import.meta.url).pathname), '..');
const veri = JSON.parse(fs.readFileSync(path.join(kok, 'km3/veri/takimlar.json'), 'utf8'));
const pano = fs.readFileSync(path.join(kok, 'www/pano.js'), 'utf8');
const W = 168, H = 20, S = 6;
const tarayici = await chromium.launch();
const s = await tarayici.newPage();
await s.setContent('<html><body></body></html>');
await s.addScriptTag({ content: pano });
await s.evaluate(() => document.fonts.load('900 20px "Archivo Black"', 'ıİşŞğĞçÇöÖüÜ').then(() => document.fonts.load('800 20px "Fira Sans"', 'ıİşŞğĞçÇöÖüÜ')));
const cikti = path.join(kok, 'km3/veri/afis'); fs.mkdirSync(cikti, { recursive: true });
for (let i = 0; i < veri.afisler.length; i++) for (const en of [false, true]) {
  const url = await s.evaluate(([A, W, H, S, en]) => MrPano.afisTuval(A, W, H, { olcek: S, en, yaziFont: '"Archivo Black", "DejaVu Sans", sans-serif', sozFont: '"Fira Sans", "DejaVu Sans", sans-serif', sozKalin: '800 ' }).toDataURL('image/webp', 0.92), [veri.afisler[i], W, H, S, en]);
  fs.writeFileSync(path.join(cikti, String(i).padStart(2, '0') + (en ? '_en' : '_tr') + '.webp'), Buffer.from(url.split(',')[1], 'base64'));
}
await tarayici.close();
console.log(veri.afisler.length * 2 + ' afiş dokusu → km3/veri/afis');
