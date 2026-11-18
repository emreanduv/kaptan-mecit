/* Mr. Anduv! ortak arma ve kupa çizicisi (F2) — Kaptan Mecit + Champion Battle Manager.
 * Aynı kulüp = aynı arma: tohum kulübün kimliğinden (id, yoksa ad), djb2 (yuz.js ve KM3 String.hash() ile aynı).
 * Arma: kalkan biçimi (6), bölüm deseni (7), simge (şehre göre: kıyı kenti → çapa/kadırga/dalga/fener,
 *       dağ kenti → karlı dağ; öteki → kule, yıldız, çınar yaprağı, meşale, güneş, lale, bozkurt, top),
 *       kısaltma şeridi. Kalem dili ortak kalemle aynı: kontur #1e130b, ışık soldan-yukarıdan, hacim, parlaklık.
 *       Gerçek kulüp armaları kopyalanmaz; yalnız kulübün iki rengi ve şehri kullanılır.
 * Kupa: tür kodundan biçim (lig, ulusal kupa, Şampiyonlar Ligi "kulaklı", Avrupa Ligi, Konferans, kıtalar arası,
 *       milli takım). Altın/gümüş metal, kurdele kulüp renginde, kaide plaketli.
 * Kupa kaldırma anı: MAArma.kupaAni({ad, kod, tur, kulup:{ad,kisa,renk1,renk2,id}, en}) tam ekran perde,
 *       projektör, konfeti, havai fişek; dokununca kapanır.
 * Kullanım: MAArma.url(kulup, px)            → data URL (önbellekli)
 *           MAArma.etiket(kulup, buyuk)       → <span class="badge arma lg"><img></span>
 *           MAArma.kupaUrl({kod,tur,k1,k2}, w, h) → data URL
 *           MAArma.ciz(ctx, x, y, w, h, kulup) / MAArma.kupaCiz(ctx, x, y, w, h, o) */
(function (G) {
  'use strict';
  var KONTUR = '#1e130b';
  function hash(s) {
    var h = 5381;
    for (var ch of String(s)) h = (((h << 5) + h) + ch.codePointAt(0)) >>> 0;
    return h;
  }
  function tohumlu(t) {
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
  function fark(a, b) { var x = rgb(a), y = rgb(b); return Math.abs(x[0] - y[0]) + Math.abs(x[1] - y[1]) + Math.abs(x[2] - y[2]); }
  function yazi(c) { return isik(c) > 150 ? '#1a1410' : '#fffaf0'; }

  var KIYI = /istanbul|izmir|trabzon|antalya|alanya|samsun|rize|giresun|mersin|bodrum|ordu|sinop|zonguldak|kocaeli|bursa|tekirdağ|çanakkale|balıkesir|aydın|muğla|hatay|iskenderun|lizbon|porto|barselona|barcelona|marsilya|napoli|cenova|genova|liverpool|amsterdam|rotterdam|hamburg|bremen|kopenhag|glasgow|aberdeen|valensiya|valencia|sevilla|bilbao|lisbon|atina|selanik|pire|odessa|bakü|baku|cádiz|vigo|malaga|málaga|palermo|bari|venedik|southampton|brighton|newcastle|sunderland|nantes|bordo|nice|lorient|brest|le havre|santos|rio|buenos/i;
  var DAGLI = /erzurum|kars|van|sivas|kayseri|ağrı|bayburt|gümüşhane|erzincan|bolu|denizli|isparta|torino|grenoble|innsbruck|salzburg|bern|zürih|zurich|cenevre|la paz|quito|bogota|tiflis|yerevan|bişkek|almatı|almaty|taşkent/i;
  var SIMGE_KIYI = ['capa', 'kadirga', 'dalga', 'fener'];
  var SIMGE_ORTA = ['kule', 'yildiz', 'cinar', 'mesale', 'gunes', 'lale', 'kurt', 'top', 'kule', 'yildiz'];
  var BICIM = ['kalkan', 'sivri', 'yuvarlak', 'madalyon', 'kose', 'kalkan'];
  var DESEN = ['capraz', 'dikey', 'yari', 'kusak', 'serit', 'kama', 'duz'];

  function ozellik(k) {
    k = k || {};
    var anahtar = String(k.id || k.ad || k.kisa || '?');
    var R = tohumlu(hash(anahtar + '#arma'));
    var r1 = k.renk1 || '#3e6a8a', r2 = k.renk2 || '#f2f2f2';
    if (fark(r1, r2) < 90) r2 = isik(r1) > 128 ? ton(r1, -0.55) : ton(r1, 0.7);
    var sehir = String(k.sehir || '');
    var liste = KIYI.test(sehir) ? SIMGE_KIYI : DAGLI.test(sehir) ? ['dag', 'dag', 'kule', 'kurt'] : SIMGE_ORTA;
    var simge = liste[Math.floor(R() * liste.length)];
    var bicim = BICIM[Math.floor(R() * BICIM.length)];
    var desen = DESEN[Math.floor(R() * DESEN.length)];
    var yildiz = R() < 0.3 ? 1 + Math.floor(R() * 3) : 0; // tepede şampiyonluk yıldızları
    return { r1: r1, r2: r2, simge: simge, bicim: bicim, desen: desen, yildiz: yildiz,
      kisa: String(k.kisa || (k.ad || '?').slice(0, 3)).toUpperCase(), cerceve: R() < 0.5 ? 'altin' : 'krem' };
  }

  /* ---------- kalkan yolları (birim kutu: x -1..1, y -1..1) ---------- */
  function bicimYolu(c, b) {
    c.beginPath();
    if (b === 'kalkan') {
      c.moveTo(-0.86, -0.86); c.quadraticCurveTo(0, -1.0, 0.86, -0.86);
      c.lineTo(0.86, -0.05); c.bezierCurveTo(0.86, 0.5, 0.42, 0.82, 0, 1.0);
      c.bezierCurveTo(-0.42, 0.82, -0.86, 0.5, -0.86, -0.05); c.closePath();
    } else if (b === 'sivri') {
      c.moveTo(0, -1.0); c.quadraticCurveTo(0.4, -0.78, 0.86, -0.8);
      c.lineTo(0.86, 0.0); c.bezierCurveTo(0.86, 0.52, 0.4, 0.8, 0, 1.0);
      c.bezierCurveTo(-0.4, 0.8, -0.86, 0.52, -0.86, 0.0); c.lineTo(-0.86, -0.8);
      c.quadraticCurveTo(-0.4, -0.78, 0, -1.0); c.closePath();
    } else if (b === 'yuvarlak') {
      c.arc(0, 0, 0.94, 0, Math.PI * 2);
    } else if (b === 'madalyon') {
      c.ellipse(0, 0, 0.8, 0.97, 0, 0, Math.PI * 2);
    } else { // kose: köşeleri içe oyulmuş kare kalkan
      var r = 0.2;
      c.moveTo(-0.86 + r, -0.9); c.lineTo(0.86 - r, -0.9); c.arc(0.86, -0.9, r, Math.PI, Math.PI / 2, true);
      c.lineTo(0.86, 0.25); c.quadraticCurveTo(0.86, 0.72, 0, 0.98); c.quadraticCurveTo(-0.86, 0.72, -0.86, 0.25);
      c.lineTo(-0.86, -0.9 + r); c.arc(-0.86, -0.9, r, Math.PI / 2, 0, true); c.closePath();
    }
  }
  function desenCiz(c, o) {
    c.fillStyle = o.r1; c.fillRect(-1.2, -1.2, 2.4, 2.4);
    c.fillStyle = o.r2; c.beginPath();
    switch (o.desen) {
      case 'capraz': c.moveTo(-1.2, 1.2); c.lineTo(1.2, -1.2); c.lineTo(1.2, 1.2); c.closePath(); break;
      case 'dikey': for (var i = -2; i <= 2; i += 2) c.rect(i * 0.19 - 0.095 + 0.19, -1.2, 0.19, 2.4); break;
      case 'yari': c.rect(0, -1.2, 1.2, 2.4); break;
      case 'kusak': c.rect(-1.2, -0.18, 2.4, 0.36); break;
      case 'serit': c.moveTo(-1.2, -0.55); c.lineTo(-0.75, -1.2); c.lineTo(1.2, 0.75); c.lineTo(1.2, 1.2); c.lineTo(0.75, 1.2); c.lineTo(-1.2, -0.75); c.closePath(); break;
      case 'kama': c.moveTo(-1.2, 1.2); c.lineTo(0, 0.05); c.lineTo(1.2, 1.2); c.closePath(); break;
      default: c.arc(0, -0.05, 0.62, 0, Math.PI * 2);
    }
    c.fill();
  }

  /* ---------- simgeler (birim kutu ~ -0.5..0.5) ---------- */
  function yildizYol(c, x, y, R, r, n) {
    n = n || 5; c.moveTo(x, y - R);
    for (var i = 1; i < n * 2; i++) { var a = -Math.PI / 2 + i * Math.PI / n, q = i % 2 ? r : R; c.lineTo(x + Math.cos(a) * q, y + Math.sin(a) * q); }
    c.closePath();
  }
  var SIMGE = {
    capa: function (c) {
      c.moveTo(-0.04, -0.34); c.lineTo(0.04, -0.34); c.lineTo(0.04, 0.32); c.lineTo(-0.04, 0.32); c.closePath();
      c.moveTo(-0.2, -0.24); c.lineTo(0.2, -0.24); c.lineTo(0.2, -0.17); c.lineTo(-0.2, -0.17); c.closePath();
      c.moveTo(0.075, -0.42); c.arc(0, -0.42, 0.075, 0, Math.PI * 2);
      c.moveTo(-0.36, 0.06); c.quadraticCurveTo(-0.32, 0.4, 0, 0.44); c.quadraticCurveTo(0.32, 0.4, 0.36, 0.06);
      c.lineTo(0.42, 0.16); c.lineTo(0.3, 0.12); c.quadraticCurveTo(0.26, 0.32, 0, 0.35);
      c.quadraticCurveTo(-0.26, 0.32, -0.3, 0.12); c.lineTo(-0.42, 0.16); c.closePath();
    },
    kadirga: function (c) {
      c.moveTo(-0.44, 0.12); c.lineTo(0.44, 0.12); c.quadraticCurveTo(0.34, 0.34, 0.2, 0.36); c.lineTo(-0.24, 0.36); c.quadraticCurveTo(-0.38, 0.3, -0.44, 0.12); c.closePath();
      c.moveTo(-0.025, 0.12); c.lineTo(-0.025, -0.44); c.lineTo(0.025, -0.44); c.lineTo(0.025, 0.12); c.closePath();
      c.moveTo(0.05, -0.38); c.quadraticCurveTo(0.34, -0.16, 0.32, 0.06); c.lineTo(0.05, 0.06); c.closePath();
      c.moveTo(-0.05, -0.32); c.quadraticCurveTo(-0.3, -0.12, -0.28, 0.06); c.lineTo(-0.05, 0.06); c.closePath();
      c.moveTo(0.03, -0.44); c.lineTo(0.18, -0.4); c.lineTo(0.03, -0.36); c.closePath();
    },
    dalga: function (c) {
      for (var j = 0; j < 3; j++) {
        var y = -0.26 + j * 0.24;
        c.moveTo(-0.44, y + 0.05);
        c.bezierCurveTo(-0.3, y - 0.12, -0.16, y - 0.12, -0.02, y + 0.02);
        c.bezierCurveTo(0.12, y - 0.12, 0.28, y - 0.12, 0.44, y + 0.03);
        c.lineTo(0.44, y + 0.12); c.bezierCurveTo(0.28, y - 0.02, 0.12, y - 0.02, -0.02, y + 0.11);
        c.bezierCurveTo(-0.16, y - 0.02, -0.3, y - 0.02, -0.44, y + 0.14); c.closePath();
      }
    },
    fener: function (c) {
      c.moveTo(-0.12, 0.38); c.lineTo(-0.08, -0.16); c.lineTo(0.08, -0.16); c.lineTo(0.12, 0.38); c.closePath();
      c.moveTo(-0.13, -0.18); c.lineTo(0.13, -0.18); c.lineTo(0.13, -0.24); c.lineTo(-0.13, -0.24); c.closePath();
      c.moveTo(-0.09, -0.26); c.lineTo(0.09, -0.26); c.lineTo(0.09, -0.36); c.lineTo(-0.09, -0.36); c.closePath();
      c.moveTo(-0.11, -0.37); c.lineTo(0, -0.46); c.lineTo(0.11, -0.37); c.closePath();
      c.moveTo(-0.2, 0.38); c.lineTo(0.2, 0.38); c.lineTo(0.24, 0.44); c.lineTo(-0.24, 0.44); c.closePath();
      c.moveTo(0.12, -0.33); c.lineTo(0.44, -0.42); c.lineTo(0.44, -0.2); c.closePath();
      c.moveTo(-0.12, -0.33); c.lineTo(-0.44, -0.42); c.lineTo(-0.44, -0.2); c.closePath();
    },
    dag: function (c) {
      c.moveTo(-0.46, 0.3); c.lineTo(-0.16, -0.16); c.lineTo(-0.06, -0.04); c.lineTo(0.12, -0.36); c.lineTo(0.46, 0.3); c.closePath();
    },
    kule: function (c) {
      c.moveTo(-0.24, 0.42); c.lineTo(-0.2, -0.18); c.lineTo(0.2, -0.18); c.lineTo(0.24, 0.42); c.closePath();
      c.moveTo(-0.3, -0.18); c.lineTo(-0.3, -0.38); c.lineTo(-0.19, -0.38); c.lineTo(-0.19, -0.3); c.lineTo(-0.06, -0.3); c.lineTo(-0.06, -0.38);
      c.lineTo(0.06, -0.38); c.lineTo(0.06, -0.3); c.lineTo(0.19, -0.3); c.lineTo(0.19, -0.38); c.lineTo(0.3, -0.38); c.lineTo(0.3, -0.18); c.closePath();
    },
    yildiz: function (c) { yildizYol(c, 0, 0.02, 0.46, 0.19, 5); },
    cinar: function (c) { // beş loplu çınar yaprağı
      c.moveTo(0, 0.24);
      var p = [[-0.12, 0.2], [-0.42, 0.18], [-0.3, 0.06], [-0.46, -0.1], [-0.26, -0.12], [-0.3, -0.36], [-0.1, -0.2], [0, -0.46],
        [0.1, -0.2], [0.3, -0.36], [0.26, -0.12], [0.46, -0.1], [0.3, 0.06], [0.42, 0.18], [0.12, 0.2]];
      for (var i = 0; i < p.length; i++) c.lineTo(p[i][0], p[i][1]);
      c.closePath();
      c.moveTo(-0.025, 0.2); c.lineTo(0.025, 0.2); c.lineTo(0.04, 0.46); c.lineTo(-0.01, 0.46); c.closePath();
    },
    mesale: function (c) {
      c.moveTo(-0.1, -0.06); c.lineTo(0.1, -0.06); c.lineTo(0.04, 0.46); c.lineTo(-0.04, 0.46); c.closePath();
      c.moveTo(-0.15, -0.06); c.lineTo(0.15, -0.06); c.lineTo(0.13, -0.13); c.lineTo(-0.13, -0.13); c.closePath();
      c.moveTo(0, -0.48); c.bezierCurveTo(0.24, -0.34, 0.2, -0.2, 0.12, -0.15); c.bezierCurveTo(0.14, -0.24, 0.06, -0.28, 0.04, -0.3);
      c.bezierCurveTo(0.04, -0.2, -0.04, -0.2, -0.04, -0.15); c.lineTo(-0.12, -0.15); c.bezierCurveTo(-0.22, -0.24, -0.12, -0.38, 0, -0.48); c.closePath();
    },
    gunes: function (c) {
      c.moveTo(0.2, 0); c.arc(0, 0, 0.2, 0, Math.PI * 2);
      for (var i = 0; i < 12; i++) {
        var a = i * Math.PI / 6, a1 = a - 0.11, a2 = a + 0.11, R = i % 2 ? 0.4 : 0.47;
        c.moveTo(Math.cos(a1) * 0.25, Math.sin(a1) * 0.25); c.lineTo(Math.cos(a) * R, Math.sin(a) * R); c.lineTo(Math.cos(a2) * 0.25, Math.sin(a2) * 0.25); c.closePath();
      }
    },
    lale: function (c) {
      c.moveTo(0, -0.08); c.bezierCurveTo(-0.08, -0.22, -0.06, -0.38, 0, -0.46); c.bezierCurveTo(0.06, -0.38, 0.08, -0.22, 0, -0.08); c.closePath();
      c.moveTo(-0.02, -0.08); c.bezierCurveTo(-0.24, -0.12, -0.28, -0.3, -0.24, -0.42); c.bezierCurveTo(-0.14, -0.3, -0.06, -0.24, -0.02, -0.18); c.closePath();
      c.moveTo(0.02, -0.08); c.bezierCurveTo(0.24, -0.12, 0.28, -0.3, 0.24, -0.42); c.bezierCurveTo(0.14, -0.3, 0.06, -0.24, 0.02, -0.18); c.closePath();
      c.moveTo(-0.022, -0.08); c.lineTo(0.022, -0.08); c.quadraticCurveTo(0.04, 0.2, 0.02, 0.46); c.lineTo(-0.02, 0.46); c.quadraticCurveTo(0, 0.2, -0.022, -0.08); c.closePath();
      c.moveTo(0, 0.3); c.bezierCurveTo(-0.16, 0.24, -0.3, 0.1, -0.3, -0.02); c.bezierCurveTo(-0.14, 0.04, -0.04, 0.16, 0, 0.24); c.closePath();
    },
    kurt: function (c) { // yandan bozkurt başı (Tamga/Kurt Yolu Bozbörü silueti, sola bakar)
      c.moveTo(0.36, 0.44); c.lineTo(0.28, 0.06); c.lineTo(0.3, -0.2); c.lineTo(0.22, -0.46); c.lineTo(0.08, -0.26);
      c.lineTo(-0.02, -0.3); c.lineTo(-0.06, -0.46); c.lineTo(-0.16, -0.22); c.lineTo(-0.3, -0.12); c.lineTo(-0.46, -0.02);
      c.lineTo(-0.44, 0.06); c.lineTo(-0.3, 0.08); c.lineTo(-0.2, 0.14); c.lineTo(-0.1, 0.28); c.lineTo(0.02, 0.44); c.closePath();
    },
    top: function (c) {
      c.moveTo(0.4, 0); c.arc(0, 0, 0.4, 0, Math.PI * 2);
    }
  };
  function simgeCiz(c, o, s, renk, golge) {
    var f = SIMGE[o.simge] || SIMGE.yildiz;
    c.save(); c.scale(s, s);
    // kontur + gölge
    c.save(); c.translate(0.025, 0.035); c.beginPath(); f(c); c.fillStyle = 'rgba(10,6,4,.35)'; c.fill('nonzero'); c.restore();
    c.beginPath(); f(c);
    c.lineJoin = 'round'; c.lineWidth = 0.06; c.strokeStyle = golge; c.stroke();
    var g = c.createLinearGradient(-0.4, -0.45, 0.35, 0.45); g.addColorStop(0, ton(renk, 0.35)); g.addColorStop(0.55, renk); g.addColorStop(1, ton(renk, -0.22));
    c.fillStyle = g; c.fill('nonzero');
    if (o.simge === 'top') { // beşgen yamalar
      c.fillStyle = golge; c.beginPath(); yildizYol(c, 0, 0, 0.13, 0.13 * 0.81, 5); c.fill();
      for (var i = 0; i < 5; i++) { var a = -Math.PI / 2 + i * 2 * Math.PI / 5; c.beginPath(); c.arc(Math.cos(a) * 0.4, Math.sin(a) * 0.4, 0.1, 0, Math.PI * 2); c.save(); c.beginPath(); c.arc(0, 0, 0.4, 0, Math.PI * 2); c.clip(); c.beginPath(); c.arc(Math.cos(a) * 0.4, Math.sin(a) * 0.4, 0.11, 0, Math.PI * 2); c.fill(); c.restore(); }
    }
    if (o.simge === 'dag') { // kar başlığı
      c.save(); c.beginPath(); f(c); c.clip(); c.fillStyle = '#fbf8f0';
      c.beginPath(); c.moveTo(0.12, -0.4); c.lineTo(0.27, -0.08); c.lineTo(0.17, -0.14); c.lineTo(0.1, -0.06); c.lineTo(0.02, -0.16); c.lineTo(-0.06, -0.06); c.closePath(); c.fill();
      c.beginPath(); c.moveTo(-0.16, -0.2); c.lineTo(-0.06, -0.05); c.lineTo(-0.13, -0.08); c.lineTo(-0.2, -0.02); c.lineTo(-0.26, -0.06); c.closePath(); c.fill(); c.restore();
    }
    if (o.simge === 'kurt') { c.fillStyle = '#ffd25a'; c.beginPath(); c.arc(-0.12, -0.08, 0.035, 0, Math.PI * 2); c.fill(); }
    if (o.simge === 'mesale') { c.fillStyle = 'rgba(255,214,90,.55)'; c.beginPath(); c.arc(0, -0.28, 0.1, 0, Math.PI * 2); c.fill(); }
    c.restore();
  }

  /* ---------- arma ---------- */
  function ciz(c, x, y, w, h, kulup, secenek) {
    secenek = secenek || {};
    var o = ozellik(kulup), buyuk = Math.min(w, h) >= 44;
    var s = Math.min(w, h) / 2;
    c.save(); c.translate(x + w / 2, y + h / 2); c.scale(s, s);
    if (o.yildiz && buyuk) { c.scale(0.88, 0.88); c.translate(0, 0.08); s *= 0.88; }
    var lw = 1 / s; // bir CSS pikseli
    // yer gölgesi
    c.save(); c.translate(0.03, 0.07); c.scale(0.97, 0.97); bicimYolu(c, o.bicim); c.fillStyle = 'rgba(20,12,6,.38)'; c.fill(); c.restore();
    // dış çerçeve (metal)
    var altin = o.cerceve === 'altin';
    var m1 = altin ? '#f7dc84' : '#fbf6ea', m2 = altin ? '#b3832a' : '#cfc5b0';
    c.save(); c.scale(0.97, 0.97); bicimYolu(c, o.bicim);
    var gm = c.createLinearGradient(-1, -1, 1, 1); gm.addColorStop(0, m1); gm.addColorStop(0.5, altin ? '#d9ae4c' : '#efe7d6'); gm.addColorStop(1, m2);
    c.fillStyle = gm; c.fill(); c.lineWidth = Math.max(0.045, 1.2 * lw); c.strokeStyle = KONTUR; c.stroke(); c.restore();
    // iç alan
    var ic = buyuk ? 0.83 : 0.8;
    c.save(); c.scale(ic, ic); bicimYolu(c, o.bicim); c.clip();
    desenCiz(c, o);
    // simge (büyük boyda ortada, küçükte yalnız soluk iz)
    if (buyuk) {
      var sr = isik(o.r1) > 150 ? ton(o.r2, 0) : '#fbf3df';
      if (fark(sr, o.r1) < 120 && fark(sr, o.r2) < 120) sr = '#f3cf5a';
      c.save(); c.translate(0, -0.2); simgeCiz(c, o, 1.12, o.simge === 'top' ? '#fbf8f0' : sr, KONTUR); c.restore();
    }
    // hacim: üst sol ışık, alt sağ gölge
    var gh = c.createRadialGradient(-0.45, -0.6, 0.05, -0.2, -0.3, 1.5);
    gh.addColorStop(0, 'rgba(255,250,235,.42)'); gh.addColorStop(0.45, 'rgba(255,250,235,.05)'); gh.addColorStop(1, 'rgba(10,6,4,.32)');
    c.fillStyle = gh; c.fillRect(-1.2, -1.2, 2.4, 2.4);
    // cam parıltısı
    c.beginPath(); c.moveTo(-1.1, -1.1); c.lineTo(0.4, -1.1); c.quadraticCurveTo(-0.1, -0.35, -1.1, -0.05); c.closePath();
    c.fillStyle = 'rgba(255,255,255,.16)'; c.fill();
    c.restore();
    // iç kontur ve ince çift halka
    c.save(); c.scale(ic, ic); bicimYolu(c, o.bicim); c.lineWidth = Math.max(0.03, 1 * lw) / ic; c.strokeStyle = KONTUR; c.stroke(); c.restore();
    if (buyuk) { c.save(); c.scale(ic - 0.06, ic - 0.06); bicimYolu(c, o.bicim); c.lineWidth = 0.012 / ic; c.strokeStyle = 'rgba(255,248,225,.55)'; c.stroke(); c.restore(); }
    // kısaltma
    var ks = o.kisa;
    c.textAlign = 'center'; c.textBaseline = 'middle';
    if (buyuk) {
      // şerit
      var sy = 0.4, sh = 0.3;
      c.beginPath(); c.moveTo(-0.98, sy - sh / 2 + 0.04); c.lineTo(0.98, sy - sh / 2 + 0.04); c.lineTo(0.88, sy + 0.02); c.lineTo(0.98, sy + sh / 2 + 0.04);
      c.lineTo(-0.98, sy + sh / 2 + 0.04); c.lineTo(-0.88, sy + 0.02); c.closePath(); c.fillStyle = 'rgba(20,12,6,.35)'; c.fill();
      c.beginPath(); c.moveTo(-0.96, sy - sh / 2); c.lineTo(0.96, sy - sh / 2); c.lineTo(0.86, sy); c.lineTo(0.96, sy + sh / 2);
      c.lineTo(-0.96, sy + sh / 2); c.lineTo(-0.86, sy); c.closePath();
      var bant = isik(o.r1) > 170 ? ton(o.r2, -0.25) : ton(o.r1, -0.35);
      var gb = c.createLinearGradient(0, sy - sh / 2, 0, sy + sh / 2); gb.addColorStop(0, ton(bant, 0.22)); gb.addColorStop(1, ton(bant, -0.2));
      c.fillStyle = gb; c.fill(); c.lineWidth = Math.max(0.03, lw); c.strokeStyle = KONTUR; c.stroke();
      c.beginPath(); c.moveTo(-0.8, sy - sh / 2 + 0.05); c.lineTo(0.8, sy - sh / 2 + 0.05); c.strokeStyle = 'rgba(255,240,200,.35)'; c.lineWidth = 0.02; c.stroke();
      c.font = '900 ' + (ks.length > 3 ? 0.21 : 0.25) + 'px Nunito, Arial, sans-serif';
      c.fillStyle = yazi(bant); c.fillText(ks, 0, sy + 0.012, 1.5);
      // tepede yıldızlar
      for (var i = 0; i < o.yildiz; i++) {
        var yx = (i - (o.yildiz - 1) / 2) * 0.22;
        c.beginPath(); yildizYol(c, yx, -1.07, 0.1, 0.042, 5); c.fillStyle = '#f6cf55'; c.fill(); c.lineWidth = 0.022; c.strokeStyle = KONTUR; c.stroke();
      }
    } else {
      var ty = o.bicim === 'kalkan' || o.bicim === 'sivri' || o.bicim === 'kose' ? -0.06 : 0;
      c.font = '900 ' + (ks.length > 3 ? 0.46 : 0.56) + 'px Nunito, Arial, sans-serif';
      var zemin = o.desen === 'duz' || o.desen === 'kusak' ? o.r1 : karis(o.r1, o.r2, 0.5);
      var yr = isik(zemin) > 140 ? '#1a1410' : '#fffaf0';
      c.lineJoin = 'round'; c.lineWidth = 0.13; c.strokeStyle = yr === '#fffaf0' ? 'rgba(20,12,6,.85)' : 'rgba(255,250,238,.9)';
      c.strokeText(ks, 0, ty, 1.45); c.fillStyle = yr; c.fillText(ks, 0, ty, 1.45);
    }
    c.restore();
  }

  var onbellek = {};
  function dpr() { return Math.min(3, Math.max(2, G.devicePixelRatio || 1)); }
  function url(kulup, px) {
    px = px || 34; kulup = kulup || {};
    var anahtar = [kulup.id || kulup.ad, kulup.renk1, kulup.renk2, kulup.kisa, px].join('|');
    if (onbellek[anahtar]) return onbellek[anahtar];
    var d = dpr(), cv = document.createElement('canvas');
    cv.width = cv.height = Math.round(px * d);
    var c = cv.getContext('2d'); c.scale(d, d);
    ciz(c, 0, 0, px, px, kulup);
    return (onbellek[anahtar] = cv.toDataURL('image/png'));
  }
  function kacis(s) { return String(s == null ? '' : s).replace(/[&<>"]/g, function (m) { return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[m]; }); }
  function etiket(kulup, buyuk) {
    kulup = kulup || {};
    return '<span class="badge arma' + (buyuk ? ' lg' : '') + '" title="' + kacis(kulup.ad) + '"><img alt="' + kacis(kulup.kisa) + '" src="' + url(kulup, buyuk ? 64 : 34) + '"></span>';
  }

  /* ---------- kupa ---------- */
  function kupaTur(o) {
    var k = String(o.kod || o.tur || '');
    if (o.tur === 'lig' || o.lig) return 'lig';
    if (o.milli || o.tur === 'milli') return 'milli';
    if (k === 'ucl') return 'kulakli';
    if (k === 'uel') return 'vazo';
    if (k === 'uecl') return 'ince';
    if (k === 'kik') return 'kure';
    if (/ipek|cnc|lib|savana/.test(k)) return ['vazo', 'kure', 'kulakli', 'ince'][hash(k) % 4];
    return 'kupa';
  }
  var PROFIL = { // kâse yarı genişliği (üst, orta, alt), kâse yüksekliği, kulp biçimi, ayak yüksekliği, kapak
    lig:     { ust: 0.36, orta: 0.34, alt: 0.12, kh: 0.46, kulp: 'yuvarlak', ayak: 0.16, kapak: 1, kaide: 0.2 },
    kupa:    { ust: 0.34, orta: 0.24, alt: 0.08, kh: 0.42, kulp: 'kivrik', ayak: 0.2, kapak: 0, kaide: 0.18 },
    kulakli: { ust: 0.26, orta: 0.3, alt: 0.1, kh: 0.5, kulp: 'kulak', ayak: 0.16, kapak: 0, kaide: 0.18 },
    vazo:    { ust: 0.2, orta: 0.3, alt: 0.12, kh: 0.56, kulp: 'ince', ayak: 0.12, kapak: 0, kaide: 0.2 },
    ince:    { ust: 0.24, orta: 0.18, alt: 0.07, kh: 0.48, kulp: 'yok', ayak: 0.24, kapak: 0, kaide: 0.16 },
    kure:    { ust: 0.0, orta: 0.0, alt: 0.0, kh: 0.0, kulp: 'yok', ayak: 0.36, kapak: 0, kaide: 0.2, kure: 1 },
    milli:   { ust: 0.0, orta: 0.0, alt: 0.0, kh: 0.0, kulp: 'yok', ayak: 0.42, kapak: 0, kaide: 0.18, kure: 1, sarmal: 1 }
  };
  function metal(c, x0, y0, x1, y1, gumus) {
    var g = c.createLinearGradient(x0, y0, x1, y1);
    var s = gumus ? ['#5d646b', '#c9d0d6', '#ffffff', '#aab3bb', '#6d757c', '#dfe5ea'] : ['#7a4e12', '#d9a43a', '#fff1b0', '#e7b84a', '#8a5a16', '#f3cf6a'];
    g.addColorStop(0, s[0]); g.addColorStop(0.18, s[1]); g.addColorStop(0.32, s[2]); g.addColorStop(0.5, s[3]); g.addColorStop(0.78, s[4]); g.addColorStop(1, s[5]);
    return g;
  }
  function kupaCiz(c, x, y, w, h, o) {
    o = o || {};
    var tur = kupaTur(o), p = PROFIL[tur], gumus = tur === 'ince' && !o.altin;
    var k1 = o.k1 || '#c0392b', k2 = o.k2 || '#f2f2f2';
    var s = Math.min(w / (tur === 'kulakli' ? 1.6 : 1.45), h / 1.32);
    c.save(); c.translate(x + w / 2, y + h / 2 - s * 0.14); c.scale(s, s);
    var lw = 1 / s;
    c.lineJoin = 'round'; c.lineCap = 'round';
    var KL = Math.max(0.012, 1.1 * lw);
    var tabanY = 0.72, kaideU = tabanY - p.kaide;
    // yer gölgesi
    var gy = c.createRadialGradient(0, tabanY + 0.02, 0.02, 0, tabanY + 0.02, 0.5);
    gy.addColorStop(0, 'rgba(10,6,4,.45)'); gy.addColorStop(1, 'rgba(10,6,4,0)');
    c.fillStyle = gy; c.beginPath(); c.ellipse(0, tabanY + 0.02, 0.5, 0.07, 0, 0, Math.PI * 2); c.fill();
    // kaide (koyu ağaç / mermer, iki kademe)
    c.beginPath(); c.moveTo(-0.34, tabanY); c.lineTo(0.34, tabanY); c.lineTo(0.3, kaideU + 0.06); c.lineTo(-0.3, kaideU + 0.06); c.closePath();
    var gk = c.createLinearGradient(-0.34, 0, 0.34, 0); gk.addColorStop(0, '#2a1a12'); gk.addColorStop(0.35, '#5a3a26'); gk.addColorStop(0.6, '#3e2718'); gk.addColorStop(1, '#1e130b');
    c.fillStyle = gk; c.fill(); c.lineWidth = KL; c.strokeStyle = KONTUR; c.stroke();
    // plaket
    c.beginPath(); c.rect(-0.16, kaideU + 0.1, 0.32, Math.max(0.05, p.kaide - 0.14)); c.fillStyle = metal(c, -0.16, 0, 0.16, 0.1, gumus); c.fill(); c.lineWidth = KL * 0.7; c.stroke();
    c.beginPath(); c.moveTo(-0.11, kaideU + 0.1 + (p.kaide - 0.14) / 2); c.lineTo(0.11, kaideU + 0.1 + (p.kaide - 0.14) / 2); c.strokeStyle = 'rgba(60,35,10,.55)'; c.lineWidth = 0.012; c.stroke();
    // üst kademe
    c.beginPath(); c.moveTo(-0.27, kaideU + 0.06); c.lineTo(0.27, kaideU + 0.06); c.lineTo(0.22, kaideU); c.lineTo(-0.22, kaideU); c.closePath();
    c.fillStyle = metal(c, -0.27, 0, 0.27, 0.06, gumus); c.fill(); c.strokeStyle = KONTUR; c.lineWidth = KL; c.stroke();
    // ayak
    var ayakU = kaideU - p.ayak;
    c.beginPath(); c.moveTo(-0.16, kaideU); c.quadraticCurveTo(-0.05, kaideU - 0.02, -0.045, kaideU - p.ayak * 0.4);
    c.lineTo(-0.035, ayakU + 0.02); c.lineTo(0.035, ayakU + 0.02); c.lineTo(0.045, kaideU - p.ayak * 0.4); c.quadraticCurveTo(0.05, kaideU - 0.02, 0.16, kaideU); c.closePath();
    c.fillStyle = metal(c, -0.16, 0, 0.16, 0, gumus); c.fill(); c.lineWidth = KL; c.stroke();
    // boğum
    c.beginPath(); c.ellipse(0, kaideU - p.ayak * 0.45, 0.075, 0.035, 0, 0, Math.PI * 2); c.fillStyle = metal(c, -0.075, 0, 0.075, 0, gumus); c.fill(); c.stroke();
    if (p.sarmal) { // milli: ayakta sarmal iki kurdele bant
      for (var sm = 0; sm < 3; sm++) { var yy = ayakU + 0.06 + sm * p.ayak * 0.22; c.beginPath(); c.ellipse(0, yy, 0.06, 0.018, -0.3, 0, Math.PI * 2); c.strokeStyle = KONTUR; c.lineWidth = KL; c.fillStyle = sm % 2 ? k1 : k2; c.fill(); c.stroke(); }
    }
    var kaseA = ayakU, kaseU = kaseA - p.kh;
    if (p.kure) {
      // küre tepeli kupa: altın kollar küreyi tutar
      var ky = ayakU - 0.24, kr = 0.24;
      for (var kl = -1; kl <= 1; kl += 2) {
        c.beginPath(); c.moveTo(kl * 0.035, ayakU + 0.02); c.bezierCurveTo(kl * 0.22, ayakU - 0.04, kl * 0.3, ky + 0.06, kl * 0.17, ky - 0.14);
        c.lineWidth = 0.07; c.strokeStyle = KONTUR; c.stroke(); c.lineWidth = 0.045; c.strokeStyle = metal(c, -0.3, 0, 0.3, 0, gumus); c.stroke();
      }
      c.beginPath(); c.arc(0, ky, kr, 0, Math.PI * 2);
      var gk2 = c.createRadialGradient(-0.09, ky - 0.1, 0.02, 0, ky, kr);
      gk2.addColorStop(0, '#fff6c8'); gk2.addColorStop(0.35, '#eabd4e'); gk2.addColorStop(0.8, '#9a6416'); gk2.addColorStop(1, '#5e3a0c');
      c.fillStyle = gk2; c.fill(); c.lineWidth = KL; c.strokeStyle = KONTUR; c.stroke();
      // kıta çizgileri (meridyen/enlem)
      c.save(); c.beginPath(); c.arc(0, ky, kr, 0, Math.PI * 2); c.clip();
      c.strokeStyle = 'rgba(90,55,12,.55)'; c.lineWidth = 0.012;
      for (var m = -2; m <= 2; m++) { c.beginPath(); c.ellipse(0, ky, Math.abs(m) * 0.08 + 0.001, kr, 0, 0, Math.PI * 2); c.stroke(); }
      for (var e = -2; e <= 2; e++) { c.beginPath(); c.ellipse(0, ky + e * 0.09, kr, 0.03, 0, 0, Math.PI * 2); c.stroke(); }
      c.restore();
      kaseU = ky - kr;
    } else {
      // kulplar (kâsenin arkasında başlar)
      var kulpRenk = metal(c, -0.6, 0, 0.6, 0, gumus);
      for (var t = -1; t <= 1; t += 2) {
        c.beginPath();
        if (p.kulp === 'yuvarlak') { c.moveTo(t * p.ust * 0.92, kaseU + 0.08); c.bezierCurveTo(t * (p.ust + 0.26), kaseU + 0.02, t * (p.ust + 0.24), kaseU + p.kh * 0.62, t * p.orta * 0.8, kaseU + p.kh * 0.72); }
        else if (p.kulp === 'kivrik') { c.moveTo(t * p.ust * 0.95, kaseU + 0.05); c.bezierCurveTo(t * (p.ust + 0.3), kaseU - 0.08, t * (p.ust + 0.22), kaseU + p.kh * 0.55, t * p.orta * 0.55, kaseU + p.kh * 0.85); }
        else if (p.kulp === 'kulak') { c.moveTo(t * p.ust * 0.9, kaseU + 0.04); c.bezierCurveTo(t * (p.ust + 0.42), kaseU - 0.12, t * (p.ust + 0.44), kaseU + p.kh * 0.9, t * p.alt * 1.2, kaseU + p.kh * 0.98); }
        else if (p.kulp === 'ince') { c.moveTo(t * p.ust, kaseU + 0.02); c.bezierCurveTo(t * (p.orta + 0.14), kaseU - 0.02, t * (p.orta + 0.16), kaseU + p.kh * 0.4, t * p.orta * 0.95, kaseU + p.kh * 0.55); }
        else continue;
        c.lineWidth = p.kulp === 'kulak' ? 0.09 : 0.075; c.strokeStyle = KONTUR; c.stroke();
        c.lineWidth = p.kulp === 'kulak' ? 0.062 : 0.05; c.strokeStyle = kulpRenk; c.stroke();
        c.lineWidth = 0.014; c.strokeStyle = 'rgba(255,248,210,.7)'; c.stroke();
      }
      // kâse
      c.beginPath(); c.moveTo(-p.ust, kaseU);
      c.bezierCurveTo(-p.orta * 1.05, kaseU + p.kh * 0.35, -p.orta * 0.95, kaseU + p.kh * 0.75, -p.alt, kaseA);
      c.lineTo(p.alt, kaseA);
      c.bezierCurveTo(p.orta * 0.95, kaseU + p.kh * 0.75, p.orta * 1.05, kaseU + p.kh * 0.35, p.ust, kaseU); c.closePath();
      c.fillStyle = metal(c, -p.orta, 0, p.orta, 0, gumus); c.fill(); c.lineWidth = KL; c.strokeStyle = KONTUR; c.stroke();
      // ağız (elips) ve iç gölge
      c.beginPath(); c.ellipse(0, kaseU, p.ust, 0.045, 0, 0, Math.PI * 2);
      c.fillStyle = gumus ? '#4c5359' : '#6a4210'; c.fill(); c.stroke();
      c.beginPath(); c.ellipse(0, kaseU + 0.004, p.ust * 0.92, 0.03, 0, Math.PI, Math.PI * 2); c.strokeStyle = 'rgba(255,240,190,.55)'; c.lineWidth = 0.012; c.stroke();
      // kabartma kuşak ve lale nakşı
      var ky2 = kaseU + p.kh * 0.38;
      c.beginPath(); c.moveTo(-p.orta * 1.02, ky2); c.quadraticCurveTo(0, ky2 + 0.05, p.orta * 1.02, ky2);
      c.strokeStyle = 'rgba(90,55,12,.6)'; c.lineWidth = 0.016; c.stroke();
      c.save(); c.translate(0, kaseU + p.kh * 0.6); c.scale(0.28, 0.28); c.beginPath(); SIMGE.lale(c);
      c.fillStyle = gumus ? 'rgba(80,88,95,.45)' : 'rgba(110,66,12,.45)'; c.fill(); c.restore();
      if (p.kapak) { // kapak ve tepe topuzu
        c.beginPath(); c.moveTo(-p.ust * 0.9, kaseU - 0.01); c.quadraticCurveTo(0, kaseU - 0.2, p.ust * 0.9, kaseU - 0.01); c.closePath();
        c.fillStyle = metal(c, -p.ust, 0, p.ust, 0, gumus); c.fill(); c.lineWidth = KL; c.strokeStyle = KONTUR; c.stroke();
        c.beginPath(); c.arc(0, kaseU - 0.17, 0.05, 0, Math.PI * 2); c.fillStyle = metal(c, -0.05, 0, 0.05, 0, gumus); c.fill(); c.stroke();
        c.beginPath(); yildizYol(c, 0, kaseU - 0.27, 0.07, 0.03, 5); c.fill(); c.stroke();
        kaseU -= 0.3;
      }
      // dikey parlak çizgi
      c.save(); c.beginPath(); c.moveTo(-p.ust, kaseU + (p.kapak ? 0.3 : 0)); c.bezierCurveTo(-p.orta * 1.05, kaseA - p.kh * 0.65, -p.orta * 0.95, kaseA - p.kh * 0.25, -p.alt, kaseA); c.lineTo(p.alt, kaseA);
      c.bezierCurveTo(p.orta * 0.95, kaseA - p.kh * 0.25, p.orta * 1.05, kaseA - p.kh * 0.65, p.ust, kaseA - p.kh); c.closePath(); c.clip();
      var gp = c.createLinearGradient(-p.orta, 0, p.orta, 0); gp.addColorStop(0.18, 'rgba(255,255,255,0)'); gp.addColorStop(0.27, 'rgba(255,255,240,.75)'); gp.addColorStop(0.33, 'rgba(255,255,255,0)');
      c.fillStyle = gp; c.fillRect(-1, -1, 2, 2); c.restore();
      // kurdeleler (kulüp renklerinde, kulplara bağlı)
      if (p.kulp !== 'yok' && !o.kurdelesiz) {
        for (var r = -1; r <= 1; r += 2) {
          var bx = r * (p.ust + (p.kulp === 'kulak' ? 0.3 : 0.17)), by = kaseU + (p.kapak ? 0.3 : 0) + p.kh * 0.25;
          for (var q = 0; q < 2; q++) {
            c.beginPath(); c.moveTo(bx, by);
            c.bezierCurveTo(bx + r * (0.06 + q * 0.04), by + 0.14, bx - r * 0.04, by + 0.26, bx + r * (0.03 + q * 0.06), by + 0.4 + q * 0.05);
            c.lineWidth = 0.06; c.strokeStyle = KONTUR; c.stroke(); c.lineWidth = 0.044; c.strokeStyle = q ? k2 : k1; c.stroke();
          }
          c.beginPath(); c.ellipse(bx, by, 0.045, 0.032, 0, 0, Math.PI * 2); c.fillStyle = k1; c.fill(); c.lineWidth = KL; c.strokeStyle = KONTUR; c.stroke();
        }
      }
    }
    // pırıltı yıldızları
    if (!o.sade) {
      var R2 = tohumlu(hash(tur + (o.kod || '')));
      for (var i = 0; i < 3; i++) {
        var px = (R2() - 0.5) * 0.7, py = kaseU + R2() * 0.5, pr = 0.04 + R2() * 0.05;
        c.beginPath(); yildizYol(c, px, py, pr, pr * 0.18, 4); c.fillStyle = 'rgba(255,252,230,.9)'; c.fill();
      }
    }
    c.restore();
  }
  var kupaOnbellek = {};
  function kupaUrl(o, w, h) {
    w = w || 40; h = h || 50;
    var a = [kupaTur(o), o.kod, o.k1, o.k2, w, h].join('|');
    if (kupaOnbellek[a]) return kupaOnbellek[a];
    var d = dpr(), cv = document.createElement('canvas'); cv.width = Math.round(w * d); cv.height = Math.round(h * d);
    var c = cv.getContext('2d'); c.scale(d, d); kupaCiz(c, 0, 0, w, h, o);
    return (kupaOnbellek[a] = cv.toDataURL('image/png'));
  }

  /* ---------- kupa kaldırma anı ---------- */
  function kupaAni(o) {
    if (!G.document || !document.body) return;
    o = o || {}; var k = o.kulup || {};
    var kf = ozellik(k), k1 = kf.r1, k2 = kf.r2;
    var en = !!o.en;
    var eski = document.getElementById('ma-kupa-ani'); if (eski) eski.remove();
    var d = document.createElement('div'); d.id = 'ma-kupa-ani';
    d.style.cssText = 'position:fixed;inset:0;z-index:99999;cursor:pointer;background:#05080c;touch-action:none';
    var cv = document.createElement('canvas'); cv.style.cssText = 'position:absolute;inset:0;width:100%;height:100%';
    d.appendChild(cv);
    var yz = document.createElement('div');
    yz.style.cssText = 'position:absolute;left:0;right:0;bottom:max(18px,env(safe-area-inset-bottom));text-align:center;color:#fff8e6;font-family:Nunito,Arial,sans-serif;pointer-events:none;text-shadow:0 2px 6px #000a;padding:0 16px';
    yz.innerHTML = '<div style="font-weight:900;font-size:clamp(26px,7vw,46px);letter-spacing:2px;color:#ffd969">' + (en ? 'CHAMPIONS!' : 'ŞAMPİYON!') + '</div>' +
      '<div style="font-weight:800;font-size:clamp(15px,3.6vw,22px);margin-top:2px">' + kacis(k.ad || '') + '</div>' +
      '<div style="font-weight:700;font-size:clamp(13px,3vw,17px);opacity:.85">' + kacis(o.ad || '') + '</div>' +
      '<div style="font-size:12px;opacity:.6;margin-top:8px">' + (en ? 'Tap to continue' : 'Devam etmek için dokun') + '</div>';
    d.appendChild(yz);
    document.body.appendChild(d);
    var c = cv.getContext('2d'), W = 0, H = 0, dp = Math.min(2, G.devicePixelRatio || 1);
    function boyut() {
      W = d.clientWidth; H = d.clientHeight; cv.width = Math.round(W * dp); cv.height = Math.round(H * dp);
      var y = W > H * 1.15; // yan ekranda yazı sağda, kupa solda
      yz.style.left = y ? '52%' : '0'; yz.style.top = y ? '50%' : 'auto'; yz.style.transform = y ? 'translateY(-50%)' : 'none';
      yz.style.bottom = y ? 'auto' : 'max(28px,env(safe-area-inset-bottom))';
    }
    boyut();
    var armaImg = new Image(); armaImg.src = url(k, 96);
    var kupaCv = document.createElement('canvas'); var KW = 220, KH = 270;
    kupaCv.width = KW * 2; kupaCv.height = KH * 2; var kc = kupaCv.getContext('2d'); kc.scale(2, 2);
    kupaCiz(kc, 0, 0, KW, KH, { kod: o.kod, tur: o.tur, lig: o.tur === 'lig', milli: o.milli, k1: k1, k2: k2, altin: 1 });
    var R = tohumlu(hash((k.ad || '') + (o.ad || '')));
    var konfeti = [], fisek = [], renkler = [k1, k2, '#ffd969', '#fff3c4', k1, k2];
    for (var i = 0; i < 160; i++) konfeti.push({ x: R(), y: -R() * 1.2, vy: 0.08 + R() * 0.12, vx: (R() - 0.5) * 0.04, a: R() * 6, va: (R() - 0.5) * 8, w: 4 + R() * 6, r: renkler[i % renkler.length], s: R() * 6 });
    var t0 = performance.now(), canli = true, sonFisek = 0;
    function cizKare(now) {
      if (!canli) return;
      var t = (now - t0) / 1000;
      if (W !== d.clientWidth || H !== d.clientHeight) boyut();
      c.setTransform(dp, 0, 0, dp, 0, 0);
      // gece stadyumu
      var g = c.createLinearGradient(0, 0, 0, H); g.addColorStop(0, '#04070d'); g.addColorStop(0.55, ton(k1, -0.82)); g.addColorStop(1, '#020305');
      c.fillStyle = g; c.fillRect(0, 0, W, H);
      // tribün ışık noktaları
      var Rt = tohumlu(7);
      for (var j = 0; j < 120; j++) { var tx = Rt() * W, ty = H * (0.45 + Rt() * 0.25), fl = 0.3 + 0.7 * Math.abs(Math.sin(t * (1 + Rt() * 3) + j)); c.fillStyle = 'rgba(255,245,220,' + (0.12 + 0.35 * fl * Rt()) + ')'; c.fillRect(tx, ty, 1.6, 1.6); }
      var yuk = Math.min(1, t / 1.4), e = 1 - Math.pow(1 - yuk, 3);
      var yatay = W > H * 1.15, mx = yatay ? W * 0.34 : W / 2;
      var kh = yatay ? Math.min(H * 0.66, W * 0.42) : Math.min(H * 0.42, W * 0.82), kw = kh * KW / KH;
      var kx = mx - kw / 2, ky = (yatay ? H * 0.42 : H * 0.36) - kh / 2 + (1 - e) * H * 0.5 + Math.sin(t * 2) * 4 * e;
      // projektör huzmeleri
      c.save(); c.globalCompositeOperation = 'lighter';
      for (var b = 0; b < 4; b++) {
        var bx = W * (b < 2 ? -0.05 : 1.05), by = H * (0.08 + (b % 2) * 0.1), hedx = mx + Math.sin(t * 0.7 + b) * W * 0.12, hedy = ky + kh * 0.5;
        var gr = c.createLinearGradient(bx, by, hedx, hedy); gr.addColorStop(0, 'rgba(255,248,220,.28)'); gr.addColorStop(1, 'rgba(255,248,220,0)');
        var ax = hedx - bx, ay = hedy - by, l = Math.hypot(ax, ay), nx = -ay / l, ny = ax / l, gen = Math.min(W, H) * 0.16;
        c.beginPath(); c.moveTo(bx, by); c.lineTo(hedx + nx * gen, hedy + ny * gen); c.lineTo(hedx - nx * gen, hedy - ny * gen); c.closePath(); c.fillStyle = gr; c.fill();
      }
      c.restore();
      // hale ve dönen ışınlar
      c.save(); c.translate(mx, ky + kh * 0.42); c.globalCompositeOperation = 'lighter';
      var hr = kh * 0.9; var hg = c.createRadialGradient(0, 0, 0, 0, 0, hr); hg.addColorStop(0, 'rgba(255,220,120,' + 0.55 * e + ')'); hg.addColorStop(1, 'rgba(255,220,120,0)');
      c.fillStyle = hg; c.beginPath(); c.arc(0, 0, hr, 0, Math.PI * 2); c.fill();
      c.rotate(t * 0.25);
      for (var rr = 0; rr < 14; rr++) { c.rotate(Math.PI * 2 / 14); c.beginPath(); c.moveTo(0, 0); c.lineTo(hr * 1.3, -hr * 0.07); c.lineTo(hr * 1.3, hr * 0.07); c.closePath(); c.fillStyle = 'rgba(255,230,150,' + 0.08 * e + ')'; c.fill(); }
      c.restore();
      c.drawImage(kupaCv, kx, ky, kw, kh);
      // arma, kupanın altında
      if (armaImg.complete && armaImg.naturalWidth) { var as = Math.min(64, H * 0.09); c.globalAlpha = e; c.drawImage(armaImg, mx - as / 2, ky + kh * 0.98, as, as); c.globalAlpha = 1; }
      // havai fişek
      if (t > 1 && now - sonFisek > 520) {
        sonFisek = now; var fx = W * (0.15 + R() * 0.7), fy = H * (0.08 + R() * 0.25), fr = renkler[Math.floor(R() * renkler.length)];
        for (var f = 0; f < 38; f++) { var aa = f / 38 * Math.PI * 2, hz = 1.4 + R() * 1.6; fisek.push({ x: fx, y: fy, vx: Math.cos(aa) * hz, vy: Math.sin(aa) * hz, o: 1, r: fr }); }
      }
      c.save(); c.globalCompositeOperation = 'lighter';
      for (var q = fisek.length - 1; q >= 0; q--) {
        var p = fisek[q]; p.x += p.vx; p.y += p.vy; p.vy += 0.03; p.vx *= 0.985; p.o -= 0.014;
        if (p.o <= 0) { fisek.splice(q, 1); continue; }
        c.fillStyle = rgba(p.r, p.o); c.beginPath(); c.arc(p.x, p.y, 1.8, 0, Math.PI * 2); c.fill();
        c.fillStyle = 'rgba(255,250,230,' + p.o * 0.5 + ')'; c.fillRect(p.x - 0.5, p.y - 0.5, 1, 1);
      }
      c.restore();
      // konfeti
      for (var n = 0; n < konfeti.length; n++) {
        var k3 = konfeti[n]; k3.y += k3.vy * 0.016 * (t < 0.6 ? 0 : 1); k3.x += k3.vx * 0.016 + Math.sin(t * 2 + k3.s) * 0.0006; k3.a += k3.va * 0.016;
        if (k3.y > 1.05) { k3.y = -0.05; k3.x = R(); }
        var cx = k3.x * W, cy = k3.y * H;
        c.save(); c.translate(cx, cy); c.rotate(k3.a); c.scale(1, Math.abs(Math.sin(t * 4 + k3.s)) + 0.15);
        c.fillStyle = k3.r; c.fillRect(-k3.w / 2, -k3.w * 0.3, k3.w, k3.w * 0.6); c.restore();
      }
      requestAnimationFrame(cizKare);
    }
    requestAnimationFrame(cizKare);
    function kapat() { canli = false; d.remove(); G.removeEventListener('keydown', tus); }
    function tus(e) { if (e.code === 'Space' || e.code === 'Enter' || e.code === 'Escape') { e.preventDefault(); kapat(); } }
    d.addEventListener('click', kapat); G.addEventListener('keydown', tus);
    try { if (navigator.vibrate) navigator.vibrate([60, 40, 120]); } catch (e) { }
    return kapat;
  }

  G.MAArma = { ozellik: ozellik, ciz: ciz, url: url, etiket: etiket, kupaCiz: kupaCiz, kupaUrl: kupaUrl, kupaTur: kupaTur, kupaAni: kupaAni, hash: hash };
})(typeof window !== 'undefined' ? window : this);
