/* Mr. Anduv! ortak yüz çizicisi (F1) — Kaptan Mecit + Champion Battle Manager.
 * Aynı ad = aynı yüz: tohum, Kaptan Mecit 3'ün (Godot) String.hash() ile birebir aynı djb2.
 * Ten / saç rengi ve saç modeli KM3'teki taktik._renk ve ana._sac_stili ile aynı seçilir:
 *   0 kısa, 1 kazınmış, 2 dolgun, 3 kıvırcık, 4 arkadan uzun.
 * Anahtar: kısa ad "U. Soyad" (KM3 verisindeki ad biçimi). CBM'de ad + soyad'dan kurulur.
 * Kalem dili ortak kalemle aynı: kontur #1e130b, ışık soldan-yukarıdan, hacim gölgesi, kenar ışığı, hale.
 * Kullanım: MAYuz.ciz(ctx, x, y, w, h, {ad, yas, rol, k1, k2, ten, sac, stil, zemin})
 *           <canvas class="yuz-p" data-yuz='{"ad":"U. Çakel","yas":24,"k1":"#a90432","k2":"#fdb912"}'>
 *           (sayfa bu tuvalleri kendiliğinden doldurur; boyut CSS'ten okunur, gerçek pikselde çizilir).
 * rol: "oyuncu" (forma), "td" (takım elbise + kravat), "asistan" (eşofman), "gazeteci" (gömlek + basın kartı),
 *      "yonetim" (takım elbise, kravat kulüp renginde), "hakem" (siyah forma). */
(function (G) {
  'use strict';
  var KONTUR = '#1e130b';
  var TENLER = ['#f1c9a5', '#e0ac7e', '#c68a5a', '#8d5a3b', '#f5d6b8'];
  var SACLAR = ['#2a1a10', '#4a2e1a', '#1a1a1a', '#7a4a20', '#c8a050'];

  // Godot 4 String::hash() — djb2, uint32, kod noktası üzerinden
  function hash(s) {
    var h = 5381;
    for (var ch of String(s)) h = (((h << 5) + h) + ch.codePointAt(0)) >>> 0;
    return h;
  }
  function kisaAd(ad, soyad) {
    ad = String(ad || '').trim(); soyad = String(soyad || '').trim();
    if (!soyad) return ad;
    return ad ? Array.from(ad)[0] + '. ' + soyad : soyad;
  }
  function tohumlu(t) { // mulberry32
    return function () {
      t = (t + 0x6D2B79F5) >>> 0; var r = Math.imul(t ^ (t >>> 15), 1 | t);
      r ^= r + Math.imul(r ^ (r >>> 7), 61 | r); return ((r ^ (r >>> 14)) >>> 0) / 4294967296;
    };
  }
  function rgb(h) {
    h = String(h || '#888').replace('#', ''); if (h.length === 3) h = h.replace(/./g, '$&$&');
    var n = parseInt(h.slice(0, 6), 16); return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
  }
  function hex(c) { return '#' + c.map(function (v) { v = Math.max(0, Math.min(255, Math.round(v))); return (v < 16 ? '0' : '') + v.toString(16); }).join(''); }
  function karis(a, b, t) { a = rgb(a); b = rgb(b); return hex([0, 1, 2].map(function (i) { return a[i] + (b[i] - a[i]) * t; })); }
  function ton(c, f) { return f >= 0 ? karis(c, '#fff6e8', f) : karis(c, '#140c08', -f); }
  function isik(c) { var r = rgb(c); return (r[0] * 299 + r[1] * 587 + r[2] * 114) / 1000; }
  function rgba(c, a) { var r = rgb(c); return 'rgba(' + r[0] + ',' + r[1] + ',' + r[2] + ',' + a + ')'; }

  function ozellik(o) {
    var ad = String(o.ad || '?');
    var h = hash(ad), R = tohumlu(hash(ad + '#yuz'));
    var rol = o.rol || 'oyuncu';
    var yas = +o.yas || (rol === 'oyuncu' ? 18 + (h % 16) : 34 + (h % 30));
    // Godot absi(String.hash()) % 100: hash uint32 → int64, pozitif
    var stil =o.stil != null ? +o.stil : (function () { var k = h % 100; return k < 45 ? 0 : k < 60 ? 1 : k < 80 ? 2 : k < 90 ? 3 : 4; })();
    var ten = o.ten || TENLER[h % 5];
    var sac = o.sac || SACLAR[(h >>> 5) % 5];
    var koyuTen = isik(ten) < 150;
    var g = {
      ad: ad, rol: rol, yas: yas, stil: stil, ten: ten, sac: sac,
      kadin: !!o.kadin,
      genis: 0.9 + R() * 0.16,          // yüz genişliği
      cene: R(),                        // 0 yuvarlak … 1 köşeli
      uzun: 0.94 + R() * 0.12,          // yüz uzunluğu
      gozAra: 0.92 + R() * 0.16,
      gozBoy: 0.85 + R() * 0.3,
      gozRenk: koyuTen ? (R() < 0.85 ? '#3a2214' : '#5a3a1e') : ['#4a2e1a', '#5a3a1e', '#6b5a2a', '#3f6f8f', '#4f7a4a', '#2f2418'][Math.floor(R() * 6)],
      kas: 0.8 + R() * 0.5, kasAci: (R() - 0.4) * 0.25,
      burun: Math.floor(R() * 3), burunBoy: 0.9 + R() * 0.25,
      agiz: Math.floor(R() * 3), gulus: (R() - 0.35) * 1.0,
      kulak: 0.9 + R() * 0.2,
      sakal: 0, // 0 yok, 1 kirli sakal, 2 bıyık, 3 keçi sakal, 4 kısa sakal, 5 gür sakal
      sacCizgi: R(), ayrik: R() < 0.5 ? -1 : 1, kabarik: R(),
      ben: R() < 0.18 ? { x: (R() - 0.5) * 22, y: 4 + R() * 10 } : null,
      kirli: R(),
      R: R
    };
    var s = R();
    if (!g.kadin && yas >= 18) {
      if (rol === 'oyuncu') g.sakal = s < 0.42 ? 0 : s < 0.66 ? 1 : s < 0.72 ? 2 : s < 0.80 ? 3 : s < 0.93 ? 4 : 5;
      else g.sakal = s < 0.35 ? 0 : s < 0.5 ? 1 : s < 0.68 ? 2 : s < 0.78 ? 3 : s < 0.92 ? 4 : 5;
    }
    // yaş: kırlaşma, saç çizgisi geri çekilir
    g.kir = Math.max(0, Math.min(0.85, (yas - 36 - R() * 8) / 26));
    g.kel = rol === 'oyuncu' ? (yas > 30 && R() < 0.15 ? 0.4 : 0) : (yas > 45 && R() < 0.35 ? (R() < 0.4 ? 1 : 0.6) : (yas > 38 && R() < 0.3 ? 0.35 : 0));
    if (g.kel >= 1) g.stil = 1;
    g.sacRenk = karis(sac, '#d9d6cf', g.kir);
    g.sakalRenk = karis(sac, '#e2dfd8', Math.min(1, g.kir * 1.2));
    return g;
  }

  /* ---------- yardımcı yollar ---------- */
  function kont(c, w) { c.lineWidth = w || 1.4; c.strokeStyle = KONTUR; c.lineJoin = 'round'; c.lineCap = 'round'; c.stroke(); }
  function elips(c, x, y, rx, ry, a) { c.beginPath(); c.ellipse(x, y, rx, ry, a || 0, 0, Math.PI * 2); }

  // baş yolu: merkez (50, 50) çevresinde, genişlik W, alın üstü üst
  function basYolu(c, g) {
    var W = 21 * g.genis, U = g.uzun, cn = g.cene;
    var ust = 26 - 2 * U, sakak = 44, cene = 70 + 6 * U, ceneG = 7 + 6 * cn;
    c.beginPath();
    c.moveTo(50, ust);
    c.bezierCurveTo(50 + W * 0.75, ust, 50 + W, ust + 8, 50 + W, sakak);
    c.bezierCurveTo(50 + W, sakak + 10, 50 + W * (0.9 - 0.05 * cn), cene - 12, 50 + ceneG + 4, cene - 2);
    c.quadraticCurveTo(50 + ceneG * 0.6, cene + 1, 50, cene + 1.5);
    c.quadraticCurveTo(50 - ceneG * 0.6, cene + 1, 50 - ceneG - 4, cene - 2);
    c.bezierCurveTo(50 - W * (0.9 - 0.05 * cn), cene - 12, 50 - W, sakak + 10, 50 - W, sakak);
    c.bezierCurveTo(50 - W, ust + 8, 50 - W * 0.75, ust, 50, ust);
    c.closePath();
    return { W: W, ust: ust, cene: cene, ceneG: ceneG, sakak: sakak };
  }

  /* ---------- gövde: rol kıyafeti ---------- */
  function govde(c, g, o, B) {
    var k1 = o.k1 || '#c8102e', k2 = o.k2 || '#ffffff';
    if (g.rol === 'hakem') { k1 = '#1b1b1b'; k2 = '#f3d35a'; }
    var omuz = 44 + g.genis * 2;
    // boyun
    var bW = 9 + g.genis * 2 + (g.kadin ? -2 : 0);
    c.beginPath(); c.moveTo(50 - bW, B.cene - 10); c.lineTo(50 - bW - 1, 92); c.lineTo(50 + bW + 1, 92); c.lineTo(50 + bW, B.cene - 10); c.closePath();
    var lg = c.createLinearGradient(50 - bW, 0, 50 + bW, 0); lg.addColorStop(0, ton(g.ten, -0.12)); lg.addColorStop(0.55, ton(g.ten, -0.05)); lg.addColorStop(1, ton(g.ten, -0.3));
    c.fillStyle = lg; c.fill(); kont(c, 1.2);
    // çene altı gölgesi
    c.save(); c.clip(); c.fillStyle = rgba('#3a1c0c', 0.32); elips(c, 50, B.cene + 1, bW + 3, 7); c.fill(); c.restore();

    // omuz/gövde yolu
    function govdeYolu() {
      c.beginPath(); c.moveTo(50 - omuz - 6, 122); c.lineTo(50 - omuz - 4, 104);
      c.bezierCurveTo(50 - omuz - 2, 94, 50 - omuz + 8, 89, 50 - bW - 4, 86);
      c.lineTo(50 + bW + 4, 86);
      c.bezierCurveTo(50 + omuz - 8, 89, 50 + omuz + 2, 94, 50 + omuz + 4, 104);
      c.lineTo(50 + omuz + 6, 122); c.closePath();
    }
    var ana = k1, kenar = k2;
    if (g.rol === 'td' || g.rol === 'yonetim') ana = g.R() < 0.5 ? '#232836' : '#2d2a28';
    else if (g.rol === 'gazeteci') ana = ['#5d7a96', '#7c8a6a', '#8a6a5a', '#4a5568'][Math.floor(g.R() * 4)];
    else if (g.rol === 'asistan') { ana = isik(k1) > 200 ? k2 : k1; kenar = isik(k1) > 200 ? k1 : k2; }
    govdeYolu();
    var gg = c.createLinearGradient(0, 86, 0, 122); gg.addColorStop(0, ton(ana, 0.12)); gg.addColorStop(1, ton(ana, -0.25));
    c.fillStyle = gg; c.fill();
    c.save(); c.clip();
    // hacim: sağ yan gölge, sol omuz ışık
    var hg = c.createLinearGradient(50 - omuz, 0, 50 + omuz, 0); hg.addColorStop(0, rgba('#ffffff', 0.18)); hg.addColorStop(0.45, rgba('#ffffff', 0)); hg.addColorStop(0.7, rgba('#000000', 0)); hg.addColorStop(1, rgba('#000000', 0.3));
    c.fillStyle = hg; c.fillRect(0, 80, 100, 50);
    if (g.rol === 'oyuncu' || g.rol === 'hakem') {
      // omuz şeritleri (kulüp ikinci rengi) + yaka
      c.fillStyle = kenar;
      c.beginPath(); c.moveTo(50 - omuz - 8, 101); c.bezierCurveTo(50 - omuz, 91, 50 - omuz + 10, 88, 50 - bW - 4, 86.5); c.lineTo(50 - bW - 4, 89.5); c.bezierCurveTo(50 - omuz + 11, 92, 50 - omuz + 2, 95, 50 - omuz - 5, 104); c.closePath(); c.fill();
      c.beginPath(); c.moveTo(50 + omuz + 8, 101); c.bezierCurveTo(50 + omuz, 91, 50 + omuz - 10, 88, 50 + bW + 4, 86.5); c.lineTo(50 + bW + 4, 89.5); c.bezierCurveTo(50 + omuz - 11, 92, 50 + omuz - 2, 95, 50 + omuz + 5, 104); c.closePath(); c.fill();
      // V yaka
      c.beginPath(); c.moveTo(50 - bW - 4, 86); c.lineTo(50, 97); c.lineTo(50 + bW + 4, 86); c.lineTo(50 + bW + 1, 86); c.lineTo(50, 93.5); c.lineTo(50 - bW - 1, 86); c.closePath();
      c.fillStyle = kenar; c.fill(); kont(c, 0.8);
      // göğüste küçük arma noktası ve kumaş dokusu
      c.fillStyle = kenar; c.beginPath(); c.moveTo(62.5, 99); c.lineTo(69.5, 99); c.lineTo(69.5, 103); c.quadraticCurveTo(69, 106.5, 66, 108); c.quadraticCurveTo(63, 106.5, 62.5, 103); c.closePath(); c.fill(); kont(c, 0.7);
      c.fillStyle = ana; elips(c, 66, 103, 1.4, 1.6); c.fill();
      c.globalAlpha = 0.07; c.fillStyle = '#000';
      for (var i = 0; i < 26; i++) c.fillRect(8 + i * 3.4, 88, 1.1, 40);
      c.globalAlpha = 1;
    } else if (g.rol === 'td' || g.rol === 'yonetim') {
      // gömlek + kravat + yaka (ceket)
      c.fillStyle = '#f4f1ea'; c.beginPath(); c.moveTo(50 - bW - 3, 86); c.lineTo(50, 112); c.lineTo(50 + bW + 3, 86); c.closePath(); c.fill();
      c.fillStyle = g.rol === 'yonetim' ? k1 : (g.R() < 0.5 ? k1 : '#3a3f52');
      c.beginPath(); c.moveTo(47.5, 89.5); c.lineTo(52.5, 89.5); c.lineTo(51.6, 93); c.lineTo(54, 118); c.lineTo(50, 122); c.lineTo(46, 118); c.lineTo(48.4, 93); c.closePath(); c.fill(); kont(c, 0.8);
      c.fillStyle = rgba('#ffffff', 0.15); c.fillRect(48.6, 95, 1.2, 20);
      // gömlek yakası
      c.fillStyle = '#ffffff';
      c.beginPath(); c.moveTo(50 - bW - 3, 85.5); c.lineTo(47.5, 90.5); c.lineTo(50 - bW + 1, 93); c.closePath(); c.fill(); kont(c, 0.7);
      c.beginPath(); c.moveTo(50 + bW + 3, 85.5); c.lineTo(52.5, 90.5); c.lineTo(50 + bW - 1, 93); c.closePath(); c.fill(); kont(c, 0.7);
      // ceket klapaları
      c.fillStyle = ton(ana, 0.1);
      c.beginPath(); c.moveTo(50 - bW - 5, 86); c.lineTo(44, 116); c.lineTo(39, 104); c.lineTo(42, 98); c.lineTo(37, 94); c.closePath(); c.fill(); kont(c, 0.8);
      c.beginPath(); c.moveTo(50 + bW + 5, 86); c.lineTo(56, 116); c.lineTo(61, 104); c.lineTo(58, 98); c.lineTo(63, 94); c.closePath(); c.fill(); kont(c, 0.8);
      // cep mendili / rozet
      c.fillStyle = k2 && isik(k2) > 60 ? k2 : '#f3d35a'; c.beginPath(); c.moveTo(66, 104); c.lineTo(72, 104); c.lineTo(70, 101); c.lineTo(68, 102.5); c.closePath(); c.fill();
    } else if (g.rol === 'asistan') {
      // eşofman: dik yaka, fermuar, kol şeritleri
      c.fillStyle = kenar; c.fillRect(50 - omuz - 6, 96, 6, 30); c.fillRect(50 + omuz, 96, 6, 30);
      c.fillStyle = ton(ana, -0.1); c.beginPath(); c.moveTo(50 - bW - 5, 83); c.lineTo(50 + bW + 5, 83); c.lineTo(50 + bW + 5, 91); c.quadraticCurveTo(50, 94, 50 - bW - 5, 91); c.closePath(); c.fill(); kont(c, 0.8);
      c.strokeStyle = ton(kenar, -0.1); c.lineWidth = 1.2; c.beginPath(); c.moveTo(50, 92.5); c.lineTo(50, 125); c.stroke();
      c.fillStyle = '#c9c9c9'; c.fillRect(48.8, 92, 2.4, 4);
      c.fillStyle = kenar; elips(c, 36, 102, 3, 3.5); c.fill(); kont(c, 0.7);
    } else if (g.rol === 'gazeteci') {
      // açık yaka gömlek, şerit (lanyard) ve basın kartı
      c.fillStyle = ton(ana, 0.18);
      c.beginPath(); c.moveTo(50 - bW - 4, 85.5); c.lineTo(46, 96); c.lineTo(50 - bW - 6, 93); c.closePath(); c.fill(); kont(c, 0.7);
      c.beginPath(); c.moveTo(50 + bW + 4, 85.5); c.lineTo(54, 96); c.lineTo(50 + bW + 6, 93); c.closePath(); c.fill(); kont(c, 0.7);
      c.fillStyle = ton(g.ten, -0.08); c.beginPath(); c.moveTo(50 - bW - 1, 86); c.lineTo(50, 96); c.lineTo(50 + bW + 1, 86); c.closePath(); c.fill();
      c.strokeStyle = '#c8102e'; c.lineWidth = 2; c.beginPath(); c.moveTo(50 - bW - 2, 87); c.quadraticCurveTo(44, 96, 47, 102); c.moveTo(50 + bW + 2, 87); c.quadraticCurveTo(56, 96, 53, 102); c.stroke();
      c.fillStyle = '#f7f4ec'; c.beginPath(); c.roundRect ? c.roundRect(42, 100, 16, 12, 1.5) : c.rect(42, 100, 16, 12); c.fill(); kont(c, 0.8);
      c.fillStyle = '#c8102e'; c.fillRect(42.6, 100.6, 14.8, 3);
      c.fillStyle = '#8a8a8a'; c.fillRect(44, 105.5, 7, 1.3); c.fillRect(44, 108, 10, 1.3);
      c.fillStyle = '#b8b2a6'; c.fillRect(52.5, 105, 4, 5);
    }
    c.restore();
    govdeYolu(); kont(c, 1.5);
  }

  /* ---------- saç ---------- */
  function sacArka(c, g, B) {
    if (g.stil === 4 || (g.kadin && g.stil !== 1)) {
      var W = B.W, uz = g.kadin ? 34 : 18;
      c.beginPath(); c.moveTo(50 - W - 3, B.sakak - 6);
      c.bezierCurveTo(50 - W - 7, B.sakak + 10, 50 - W - 6, B.sakak + uz, 50 - W + 3, B.sakak + uz + 6);
      c.lineTo(50 + W - 3, B.sakak + uz + 6);
      c.bezierCurveTo(50 + W + 6, B.sakak + uz, 50 + W + 7, B.sakak + 10, 50 + W + 3, B.sakak - 6);
      c.closePath();
      c.fillStyle = ton(g.sacRenk, -0.25); c.fill(); kont(c, 1.4);
      c.save(); c.clip(); c.strokeStyle = rgba('#000', 0.25); c.lineWidth = 0.7;
      for (var i = -3; i <= 3; i++) { c.beginPath(); c.moveTo(50 + i * W / 3.5, B.sakak - 4); c.quadraticCurveTo(50 + i * W / 3 + 2, B.sakak + uz / 2, 50 + i * W / 3.2, B.sakak + uz + 6); c.stroke(); }
      c.restore();
    }
    if (g.stil === 3) { // kıvırcık hacim arkada
      c.fillStyle = ton(g.sacRenk, -0.3);
      var R2 = tohumlu(hash(g.ad + '#kivir2'));
      for (var j = 0; j < 22; j++) { var a = Math.PI * (1.0 + j / 21), r = B.W + 4 + R2() * 2; elips(c, 50 + Math.cos(a) * r, B.sakak - 4 + Math.sin(a) * (r + 2), 5, 5); c.fill(); kont(c, 0.9); }
    }
  }

  function sacOn(c, g, B) {
    var W = B.W, ust = B.ust, renk = g.sacRenk, R = tohumlu(hash(g.ad + '#sac'));
    var cizgi = ust + 9 + g.sacCizgi * 3 + g.kel * 9; // alın üstü saç çizgisi
    function dolgu(yol, isikli) {
      yol(); var gr = c.createLinearGradient(50 - W, ust - 8, 50 + W, cizgi + 4);
      gr.addColorStop(0, ton(renk, 0.25)); gr.addColorStop(0.5, renk); gr.addColorStop(1, ton(renk, -0.35));
      c.fillStyle = gr; c.fill();
      if (isikli) { c.save(); c.clip(); c.strokeStyle = rgba(ton(renk, 0.6), 0.55); c.lineWidth = 0.9;
        for (var i = 0; i < 7; i++) { var x = 50 - W * 0.6 + i * W * 0.17; c.beginPath(); c.moveTo(x, ust - 2); c.quadraticCurveTo(x - 3, ust + 4, x - 5 + R() * 2, cizgi - 2); c.stroke(); }
        c.fillStyle = rgba('#fff8e0', 0.18); elips(c, 50 - W * 0.35, ust + 2, W * 0.35, 3.5, -0.3); c.fill(); c.restore(); }
      yol(); kont(c, 1.4);
    }
    if (g.stil === 1) { // kazınmış: ince örtü + nokta dokusu
      if (g.kel >= 1) return;
      c.save(); basYolu(c, g); c.clip();
      c.beginPath(); c.moveTo(50 - W - 2, B.sakak - 1); c.bezierCurveTo(50 - W, ust - 2, 50 + W, ust - 2, 50 + W + 2, B.sakak - 1);
      c.lineTo(50 + W - 3, B.sakak - 2); c.quadraticCurveTo(50 + W * 0.6, cizgi - 1, 50, cizgi); c.quadraticCurveTo(50 - W * 0.6, cizgi - 1, 50 - W + 3, B.sakak - 2); c.closePath();
      c.fillStyle = rgba(renk, 0.55); c.fill();
      c.fillStyle = rgba(ton(renk, -0.3), 0.5);
      for (var i = 0; i < 160; i++) { var x = 50 + (R() - 0.5) * W * 2, y = ust + R() * (cizgi - ust + 2); c.fillRect(x, y, 0.55, 0.55); }
      c.restore(); return;
    }
    if (g.kel >= 1) return;
    if (g.stil === 0) { // kısa
      dolgu(function () {
        c.beginPath(); c.moveTo(50 - W - 1.5, B.sakak + 1);
        c.bezierCurveTo(50 - W - 2.5, ust - 2, 50 - 6, ust - 5, 50 + 2, ust - 4.5);
        c.bezierCurveTo(50 + W, ust - 4, 50 + W + 2.5, ust + 6, 50 + W + 1.5, B.sakak + 1);
        c.lineTo(50 + W - 1.5, B.sakak - 3);
        c.quadraticCurveTo(50 + W * 0.7, cizgi - 1, 50 + W * 0.3, cizgi + 0.5);
        for (var i = 0; i < 6; i++) { var x = 50 + W * 0.3 - (i + 1) * W * 0.6 / 6; c.lineTo(x + W * 0.05, cizgi + (i % 2 ? 2.4 : -0.3)); }
        c.quadraticCurveTo(50 - W * 0.8, cizgi - 1, 50 - W + 1.5, B.sakak - 3);
        c.closePath();
      }, true);
    } else if (g.stil === 2) { // dolgun: yukarı kabarık perçem
      var k = 5 + g.kabarik * 4;
      dolgu(function () {
        c.beginPath(); c.moveTo(50 - W - 2, B.sakak + 1);
        c.bezierCurveTo(50 - W - 5, ust - 6, 50 - W * 0.5, ust - k - 4, 50 + 2, ust - k - 3);
        c.bezierCurveTo(50 + W * 0.7, ust - k - 3, 50 + W + 5, ust - 4, 50 + W + 2, B.sakak + 1);
        c.lineTo(50 + W - 1.5, B.sakak - 3);
        c.bezierCurveTo(50 + W * 0.8, cizgi - 4, 50 + W * 0.3, cizgi - 4, 50 + W * 0.1 * g.ayrik, cizgi - 1);
        c.bezierCurveTo(50 - W * 0.3, cizgi + 2, 50 - W * 0.8, cizgi - 1, 50 - W + 1.5, B.sakak - 3);
        c.closePath();
      }, true);
      c.strokeStyle = rgba(ton(renk, -0.5), 0.6); c.lineWidth = 0.8;
      for (var i = 0; i < 5; i++) { var x = 50 - W * 0.6 + i * W * 0.3; c.beginPath(); c.moveTo(x, ust - k); c.quadraticCurveTo(x + 4, ust - 2, x + 2, cizgi - 3); c.stroke(); }
    } else if (g.stil === 3) { // kıvırcık
      var R2 = tohumlu(hash(g.ad + '#kivir'));
      var pts = [];
      for (var i = 0; i < 26; i++) { var a = Math.PI * (1.02 + 0.96 * i / 25), r = W + 1 + R2() * 2.5; pts.push([50 + Math.cos(a) * r, ust + 13 + Math.sin(a) * (r * 0.85)]); }
      for (var j = 0; j < 14; j++) pts.push([50 + (R2() - 0.5) * W * 1.6, ust - 3 + R2() * 9]);
      for (var m = 0; m < 9; m++) pts.push([50 - W * 0.8 + m * W * 0.2, cizgi - 1 + R2() * 1.5]);
      pts.forEach(function (p, ix) {
        var rr = 3.6 + R2() * 1.6; elips(c, p[0], p[1], rr, rr);
        var gr = c.createRadialGradient(p[0] - 1.2, p[1] - 1.2, 0.3, p[0], p[1], rr);
        gr.addColorStop(0, ton(renk, 0.35)); gr.addColorStop(1, ton(renk, -0.3)); c.fillStyle = gr; c.fill(); kont(c, 0.75);
        c.strokeStyle = rgba(ton(renk, 0.5), 0.5); c.lineWidth = 0.6; c.beginPath(); c.arc(p[0], p[1], rr * 0.5, Math.PI, Math.PI * 1.7); c.stroke();
      });
    } else if (g.stil === 4) { // arkadan uzun, ortadan/yandan ayrık
      var ay = 50 + g.ayrik * W * 0.25;
      dolgu(function () {
        c.beginPath(); c.moveTo(50 - W - 3, B.sakak + 10);
        c.bezierCurveTo(50 - W - 5, ust - 5, ay - 6, ust - 7, ay, ust - 5);
        c.bezierCurveTo(ay + 6, ust - 7, 50 + W + 5, ust - 5, 50 + W + 3, B.sakak + 10);
        c.lineTo(50 + W - 1, B.sakak + 6);
        c.bezierCurveTo(50 + W - 2, cizgi + 2, ay + 8, cizgi - 3, ay, cizgi - 4);
        c.bezierCurveTo(ay - 8, cizgi - 3, 50 - W + 2, cizgi + 2, 50 - W + 1, B.sakak + 6);
        c.closePath();
      }, true);
      c.strokeStyle = rgba(ton(renk, -0.5), 0.55); c.lineWidth = 0.8;
      c.beginPath(); c.moveTo(ay, ust - 4); c.lineTo(ay, cizgi - 4); c.stroke();
    }
    // favoriler
    if (g.stil !== 3 && !g.kadin) { c.fillStyle = ton(renk, -0.1);
      [-1, 1].forEach(function (y) { c.beginPath(); c.moveTo(50 + y * (W - 0.3), B.sakak - 3); c.lineTo(50 + y * (W - 3.2), B.sakak - 3); c.lineTo(50 + y * (W - 2.6), B.sakak + 4.5 + (g.sakal >= 4 ? 4 : 0)); c.lineTo(50 + y * (W - 0.4), B.sakak + 4.5 + (g.sakal >= 4 ? 4 : 0)); c.closePath(); c.fill(); }); }
    // kırlaşma tutamları
    if (g.kir > 0.15) {
      c.strokeStyle = rgba('#efece6', Math.min(0.7, g.kir)); c.lineWidth = 0.7;
      for (var q = 0; q < 10; q++) { var x0 = 50 + (R() - 0.5) * W * 1.8; c.beginPath(); c.moveTo(x0, ust + 1); c.lineTo(x0 - 2, ust + 6); c.stroke(); }
    }
  }

  /* ---------- yüz ayrıntıları ---------- */
  function goz(c, g, x, y, yon) {
    var b = g.gozBoy, gw = 4.4, gh = 2.5 * b;
    // göz çukuru gölgesi
    c.fillStyle = rgba('#5a2a14', 0.12); elips(c, x, y - 0.6, gw + 1.6, gh + 1.6); c.fill();
    // ak
    c.beginPath(); c.moveTo(x - gw, y); c.quadraticCurveTo(x - gw * 0.2, y - gh * 1.5, x + gw, y - 0.2 * yon); c.quadraticCurveTo(x, y + gh * 1.1, x - gw, y); c.closePath();
    c.fillStyle = '#f8f4ec'; c.fill();
    c.save(); c.clip();
    var ir = 2.15;
    var gr = c.createRadialGradient(x + 0.2, y - 0.2, 0.2, x + 0.2, y - 0.1, ir);
    gr.addColorStop(0, ton(g.gozRenk, 0.35)); gr.addColorStop(0.7, g.gozRenk); gr.addColorStop(1, ton(g.gozRenk, -0.5));
    c.fillStyle = gr; elips(c, x + 0.2, y - 0.1, ir, ir); c.fill();
    c.fillStyle = '#0c0805'; elips(c, x + 0.2, y - 0.1, 1.0, 1.0); c.fill();
    c.fillStyle = rgba('#3a1c0c', 0.25); c.fillRect(x - gw, y - gh * 2, gw * 2, gh * 0.9); // üst kapak gölgesi
    c.restore();
    c.fillStyle = '#ffffff'; elips(c, x - 0.6, y - 0.9, 0.65, 0.65); c.fill();
    // üst kapak çizgisi (kalın), alt ince
    c.beginPath(); c.moveTo(x - gw - 0.4, y + 0.2); c.quadraticCurveTo(x - gw * 0.2, y - gh * 1.55, x + gw + 0.3, y - 0.3 * yon);
    c.strokeStyle = KONTUR; c.lineWidth = 1.25; c.stroke();
    c.beginPath(); c.moveTo(x - gw * 0.6, y + gh * 0.55); c.quadraticCurveTo(x, y + gh * 0.95, x + gw * 0.7, y + gh * 0.4);
    c.strokeStyle = rgba('#3a1c0c', 0.45); c.lineWidth = 0.6; c.stroke();
    // kapak kıvrımı
    c.beginPath(); c.moveTo(x - gw * 0.8, y - gh * 1.15); c.quadraticCurveTo(x, y - gh * 2.0, x + gw * 0.9, y - gh * 1.0);
    c.strokeStyle = rgba('#3a1c0c', 0.3); c.lineWidth = 0.6; c.stroke();
  }
  function kas(c, g, x, y, yon) {
    var renk = karis(g.sacRenk === g.sac ? g.sac : g.sacRenk, '#000', 0.1);
    var k = g.kas, a = g.kasAci * yon;
    c.save(); c.translate(x, y); c.rotate(a);
    c.beginPath(); c.moveTo(-5.2 * yon, 1.1); c.quadraticCurveTo(-1 * yon, -1.6 - k * 0.6, 5.4 * yon, -0.2);
    c.quadraticCurveTo(0, -0.4 - k * 0.2 + 1.6 * k, -5.2 * yon, 1.1 + 0.4);
    c.closePath(); c.fillStyle = renk; c.fill();
    c.strokeStyle = rgba(renk, 0.8); c.lineWidth = 0.9 * k; c.stroke();
    c.restore();
  }
  function yuzAyrinti(c, g, B) {
    var gy = 46, ga = 9.2 * g.gozAra * Math.min(1.05, g.genis);
    // yanak kızarıklığı ve hacim
    c.save(); basYolu(c, g); c.clip();
    var hg = c.createLinearGradient(50 - B.W, 0, 50 + B.W, 0);
    hg.addColorStop(0, rgba('#fff4e0', 0.22)); hg.addColorStop(0.35, rgba('#fff4e0', 0)); hg.addColorStop(0.62, rgba('#3a1608', 0)); hg.addColorStop(1, rgba('#3a1608', 0.38));
    c.fillStyle = hg; c.fillRect(0, 0, 100, 100);
    // alın ışığı
    var al = c.createRadialGradient(44, B.ust + 10, 1, 44, B.ust + 10, 16); al.addColorStop(0, rgba('#fff8ec', 0.28)); al.addColorStop(1, rgba('#fff8ec', 0));
    c.fillStyle = al; c.fillRect(0, 0, 100, 100);
    c.fillStyle = rgba('#d0503c', 0.10); elips(c, 50 - ga - 2, 57, 6, 3.5); c.fill(); elips(c, 50 + ga + 2, 57, 6, 3.5); c.fill();
    // çene altı ve şakak gölgesi
    c.fillStyle = rgba('#3a1608', 0.12); elips(c, 50 + B.W - 2, gy + 6, 4, 10); c.fill();
    // sakal / kirli sakal (yüzün içinde)
    if (g.sakal === 1 || g.sakal >= 4) {
      var yo = g.sakal === 5 ? 0.85 : g.sakal === 4 ? 0.65 : 0.22;
      c.fillStyle = rgba(g.sakalRenk, yo * 0.55);
      c.beginPath(); c.moveTo(50 - B.W, gy + 6); c.quadraticCurveTo(50 - B.W + 3, 60, 50 - 10, 60); c.quadraticCurveTo(50, 57.5, 50 + 10, 60);
      c.quadraticCurveTo(50 + B.W - 3, 60, 50 + B.W, gy + 6); c.lineTo(50 + B.W, 100); c.lineTo(50 - B.W, 100); c.closePath(); c.fill();
      var R3 = tohumlu(hash(g.ad + '#sakal')); c.fillStyle = rgba(ton(g.sakalRenk, -0.3), yo * 0.6);
      for (var i = 0; i < 260 * yo; i++) { var x = 50 + (R3() - 0.5) * B.W * 2, y = 54 + R3() * (B.cene - 52); c.fillRect(x, y, 0.5, 0.5); }
      // ağız çevresi açıklığı (dudak)
    }
    if (g.yas >= 30) { // alın çizgileri
      c.strokeStyle = rgba('#5a2a14', Math.min(0.35, (g.yas - 28) / 60)); c.lineWidth = 0.55;
      for (var l = 0; l < (g.yas >= 45 ? 3 : 2); l++) { c.beginPath(); c.moveTo(50 - 8 + l, B.ust + 10 + l * 2.3); c.quadraticCurveTo(50, B.ust + 9 + l * 2.3, 50 + 8 - l, B.ust + 10 + l * 2.3); c.stroke(); }
    }
    c.restore();

    kas(c, g, 50 - ga, gy - 6.2, -1); kas(c, g, 50 + ga, gy - 6.2, 1);
    goz(c, g, 50 - ga, gy, -1); goz(c, g, 50 + ga, gy, 1);
    if (g.yas >= 40) { // kaz ayağı, göz altı
      c.strokeStyle = rgba('#5a2a14', 0.3); c.lineWidth = 0.5;
      [-1, 1].forEach(function (s) { var x = 50 + s * (ga + 5.5); for (var i = -1; i <= 1; i++) { c.beginPath(); c.moveTo(x, gy + i * 1.4); c.lineTo(x + s * 2.2, gy + i * 2.1); c.stroke(); } });
    }
    // burun
    var nb = g.burunBoy, ny = 55 + 2 * nb;
    c.strokeStyle = rgba('#5a2a14', 0.45); c.lineWidth = 0.9;
    c.beginPath(); c.moveTo(50 + 2, gy + 1); c.quadraticCurveTo(50 + 3.6, ny - 5, 50 + 3.4 + g.burun * 0.6, ny - 1); c.stroke();
    c.fillStyle = rgba('#5a2a14', 0.18); c.beginPath(); c.moveTo(50 + 1.2, gy + 3); c.quadraticCurveTo(50 + 4, ny - 4, 50 + 4.2, ny); c.lineTo(50 + 1.5, ny - 1); c.closePath(); c.fill();
    var kanat = 3.6 + g.burun * 0.7;
    c.fillStyle = rgba('#fff4e0', 0.35); elips(c, 50 - 0.8, ny - 2.2, 1.4, 1.1); c.fill();
    c.strokeStyle = KONTUR; c.lineWidth = 0.95;
    c.beginPath(); c.moveTo(50 - kanat, ny - 1.4); c.quadraticCurveTo(50 - kanat - 1, ny + 0.8, 50 - 1.6, ny + 0.6);
    c.moveTo(50 + kanat, ny - 1.4); c.quadraticCurveTo(50 + kanat + 1, ny + 0.8, 50 + 1.6, ny + 0.6); c.stroke();
    c.fillStyle = rgba('#2a0e04', 0.6); elips(c, 50 - 1.9, ny + 0.2, 1.0, 0.55); c.fill(); elips(c, 50 + 1.9, ny + 0.2, 1.0, 0.55); c.fill();
    // ağız
    var ay = ny + 6.2 + (B.cene - 72) * 0.25, aw = 5.5 + g.agiz * 0.8, gl = g.gulus;
    var dudak = karis(g.ten, '#b0483c', 0.35);
    c.fillStyle = dudak;
    c.beginPath(); c.moveTo(50 - aw, ay - gl * 0.6); c.quadraticCurveTo(50, ay + 3.2 + gl * 0.6, 50 + aw, ay - gl * 0.6); c.quadraticCurveTo(50, ay + 0.6, 50 - aw, ay - gl * 0.6); c.fill();
    c.fillStyle = ton(dudak, -0.15);
    c.beginPath(); c.moveTo(50 - aw + 0.5, ay - gl * 0.6); c.quadraticCurveTo(50 - 2, ay - 1.8, 50, ay - 1.0); c.quadraticCurveTo(50 + 2, ay - 1.8, 50 + aw - 0.5, ay - gl * 0.6); c.quadraticCurveTo(50, ay + 0.4, 50 - aw + 0.5, ay - gl * 0.6); c.fill();
    c.strokeStyle = KONTUR; c.lineWidth = 1.0;
    c.beginPath(); c.moveTo(50 - aw, ay - gl * 0.6); c.quadraticCurveTo(50, ay + 0.9 + gl * 0.8, 50 + aw, ay - gl * 0.6); c.stroke();
    if (gl > 0.25) { c.lineWidth = 0.6; c.strokeStyle = rgba('#5a2a14', 0.5); c.beginPath(); c.arc(50 - aw - 0.6, ay - gl * 0.6 - 0.8, 1.2, 0.3, 1.6); c.stroke(); c.beginPath(); c.arc(50 + aw + 0.6, ay - gl * 0.6 - 0.8, 1.2, 1.5, 2.8); c.stroke(); }
    c.fillStyle = rgba('#fff4e0', 0.3); elips(c, 50 - 1, ay + 2.2, 2.2, 0.7); c.fill();
    if (g.yas >= 38) { c.strokeStyle = rgba('#5a2a14', 0.28); c.lineWidth = 0.6; c.beginPath(); c.moveTo(50 - kanat - 1, ny); c.quadraticCurveTo(50 - aw - 3, ay - 2, 50 - aw - 2, ay + 3); c.moveTo(50 + kanat + 1, ny); c.quadraticCurveTo(50 + aw + 3, ay - 2, 50 + aw + 2, ay + 3); c.stroke(); }
    // bıyık / keçi sakal / sakal
    var sr = g.sakalRenk;
    if (g.sakal === 2 || g.sakal >= 3) {
      c.fillStyle = sr; c.beginPath(); c.moveTo(50 - aw - 1.6, ay + 0.4); c.quadraticCurveTo(50 - aw, ny + 1.4, 50, ny + 2.4); c.quadraticCurveTo(50 + aw, ny + 1.4, 50 + aw + 1.6, ay + 0.4);
      c.quadraticCurveTo(50 + aw - 1, ay - 2.2, 50, ay - 1.6); c.quadraticCurveTo(50 - aw + 1, ay - 2.2, 50 - aw - 1.6, ay + 0.4); c.fill(); kont(c, 0.6);
    }
    if (g.sakal === 3) { c.fillStyle = sr; c.beginPath(); c.moveTo(50 - 4, ay + 3); c.quadraticCurveTo(50, ay + 2, 50 + 4, ay + 3); c.lineTo(50 + 3, B.cene + 1); c.quadraticCurveTo(50, B.cene + 3, 50 - 3, B.cene + 1); c.closePath(); c.fill(); kont(c, 0.6); }
    if (g.sakal >= 4) {
      var gur = g.sakal === 5 ? 3.5 : 1.2;
      c.fillStyle = sr; c.beginPath(); c.moveTo(50 - B.W + 0.5, gy + 7);
      c.bezierCurveTo(50 - B.W + 1, B.cene - 4, 50 - B.ceneG - 4, B.cene + gur, 50, B.cene + 1.5 + gur);
      c.bezierCurveTo(50 + B.ceneG + 4, B.cene + gur, 50 + B.W - 1, B.cene - 4, 50 + B.W - 0.5, gy + 7);
      c.lineTo(50 + B.W - 2.5, gy + 9); c.quadraticCurveTo(50 + aw + 4, ay + 6, 50, ay + 4.2); c.quadraticCurveTo(50 - aw - 4, ay + 6, 50 - B.W + 2.5, gy + 9); c.closePath();
      c.fill(); kont(c, 0.9);
      c.save(); c.clip(); c.strokeStyle = rgba(ton(sr, 0.4), 0.4); c.lineWidth = 0.5;
      for (var i = 0; i < 12; i++) { var x = 50 - B.W + 3 + i * B.W / 6; c.beginPath(); c.moveTo(x, ay + 4); c.lineTo(x + 0.6, B.cene + gur); c.stroke(); } c.restore();
    }
    if (g.ben) { c.fillStyle = rgba('#3a1608', 0.65); elips(c, 50 + g.ben.x, gy + g.ben.y, 0.7, 0.7); c.fill(); }
  }

  function kulak(c, g, B, yon) {
    var x = 50 + yon * (B.W - 0.5), y = 49, k = g.kulak;
    c.beginPath(); c.moveTo(x, y - 6 * k); c.bezierCurveTo(x + yon * 5.5 * k, y - 8 * k, x + yon * 6 * k, y + 3, x + yon * 1, y + 6 * k); c.closePath();
    c.fillStyle = yon < 0 ? ton(g.ten, -0.02) : ton(g.ten, -0.22); c.fill(); kont(c, 1.2);
    c.strokeStyle = rgba('#5a2a14', 0.45); c.lineWidth = 0.7; c.beginPath(); c.moveTo(x + yon * 1.2, y - 3.5 * k); c.quadraticCurveTo(x + yon * 4 * k, y - 4 * k, x + yon * 2.2, y + 2.5 * k); c.stroke();
  }

  function zeminCiz(c, g, o) {
    var k1 = o.k1 || '#2e9e44';
    var gr = c.createRadialGradient(46, 40, 4, 50, 56, 66);
    gr.addColorStop(0, ton(k1, 0.55)); gr.addColorStop(0.55, ton(k1, 0.1)); gr.addColorStop(1, ton(k1, -0.45));
    c.fillStyle = gr; c.fillRect(0, 0, 100, 120);
    // hale
    var h = c.createRadialGradient(50, 50, 10, 50, 50, 46); h.addColorStop(0, rgba('#fff8e6', 0.55)); h.addColorStop(1, rgba('#fff8e6', 0));
    c.fillStyle = h; c.fillRect(0, 0, 100, 120);
    // ışık hüzmesi çizgileri
    c.globalAlpha = 0.08; c.fillStyle = '#fff';
    for (var i = 0; i < 5; i++) { c.beginPath(); c.moveTo(10 + i * 18, 0); c.lineTo(18 + i * 18, 0); c.lineTo(i * 18 - 6, 120); c.lineTo(i * 18 - 14, 120); c.closePath(); c.fill(); }
    c.globalAlpha = 1;
  }

  // ana çizici: (x, y, w, h) kutusuna sığdırır; mantıksal tuval 100 × 120
  function ciz(ctx, x, y, w, h, o) {
    o = o || {}; var g = ozellik(o);
    ctx.save(); ctx.translate(x, y);
    var s = Math.min(w / 100, h / 120); ctx.translate((w - 100 * s) / 2, (h - 120 * s) / 2); ctx.scale(s, s);
    ctx.beginPath(); ctx.rect(0, 0, 100, 120); ctx.clip();
    if (o.zemin !== false) zeminCiz(ctx, g, o);
    var z = o.yakin || 1.14; ctx.translate(50, 58); ctx.scale(z, z); ctx.translate(-50, -54);
    ctx.save(); ctx.beginPath(); ctx.rect(-10, -10, 120, 130); ctx.clip();
    var B = basYolu(ctx, g); ctx.beginPath();
    sacArka(ctx, g, B);
    govde(ctx, g, o, B);
    kulak(ctx, g, B, -1); kulak(ctx, g, B, 1);
    basYolu(ctx, g);
    var tg = ctx.createLinearGradient(50 - B.W, B.ust, 50 + B.W * 0.6, B.cene);
    tg.addColorStop(0, ton(g.ten, 0.1)); tg.addColorStop(0.6, g.ten); tg.addColorStop(1, ton(g.ten, -0.12));
    ctx.fillStyle = tg; ctx.fill();
    yuzAyrinti(ctx, g, B);
    basYolu(ctx, g); kont(ctx, 1.6);
    // kenar ışığı (sol yanak/şakak)
    ctx.save(); basYolu(ctx, g); ctx.clip(); ctx.strokeStyle = rgba('#fffbe8', 0.5); ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.moveTo(50 - B.W + 1.2, B.sakak - 8); ctx.quadraticCurveTo(50 - B.W + 0.6, B.sakak + 6, 50 - B.W + 3, B.sakak + 14); ctx.stroke(); ctx.restore();
    sacOn(ctx, g, B);
    ctx.restore();
    ctx.restore(); ctx.save(); ctx.translate(x, y); ctx.translate((w - 100 * s) / 2, (h - 120 * s) / 2); ctx.scale(s, s);
    if (o.zemin !== false) { // kenar karartması
      var v = ctx.createRadialGradient(50, 56, 40, 50, 60, 78); v.addColorStop(0, 'rgba(0,0,0,0)'); v.addColorStop(1, 'rgba(0,0,0,0.35)');
      ctx.fillStyle = v; ctx.fillRect(0, 0, 100, 120);
    }
    ctx.restore();
    return g;
  }

  // sayfadaki <canvas class="yuz-p" data-yuz='{…}'> tuvallerini gerçek pikselde doldur
  function doldur(kok) {
    var L = (kok || document).querySelectorAll('canvas.yuz-p');
    for (var i = 0; i < L.length; i++) {
      var cv = L[i], v = cv.getAttribute('data-yuz') || '';
      var r = cv.getBoundingClientRect(); if (!r.width) continue;
      var dpr = Math.min(3, window.devicePixelRatio || 1), W = Math.round(r.width * dpr), H = Math.round(r.height * dpr);
      if (cv.__yuz === v && cv.width === W && cv.height === H) continue;
      var o; try { o = JSON.parse(decodeURIComponent(v)); } catch (e) { o = { ad: v }; }
      if (o.soyad != null) { o.ad = kisaAd(o.ad, o.soyad); }
      cv.width = W; cv.height = H; cv.__yuz = v;
      var c = cv.getContext('2d'); c.clearRect(0, 0, W, H); ciz(c, 0, 0, W, H, o);
    }
  }
  var bekle = 0;
  function izle() {
    if (typeof MutationObserver === 'undefined' || !document.body) return;
    new MutationObserver(function () { if (!bekle) bekle = requestAnimationFrame(function () { bekle = 0; doldur(); }); })
      .observe(document.body, { childList: true, subtree: true });
    window.addEventListener('resize', function () { setTimeout(doldur, 60); });
    doldur();
  }
  if (typeof document !== 'undefined') {
    if (document.readyState === 'loading') document.addEventListener('DOMContentLoaded', izle); else izle();
  }
  // HTML içine konacak tuval etiketi
  function etiket(o, sinif) { return '<canvas class="yuz-p' + (sinif ? ' ' + sinif : '') + '" data-yuz="' + encodeURIComponent(JSON.stringify(o)) + '" aria-hidden="true"></canvas>'; }
  G.MAYuz = { ciz: ciz, doldur: doldur, etiket: etiket, hash: hash, kisaAd: kisaAd, ozellik: ozellik, TENLER: TENLER, SACLAR: SACLAR };
})(typeof window !== 'undefined' ? window : globalThis);
