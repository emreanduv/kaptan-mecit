/* Kaptan Mecit (Klasik) · Klasik kumanda (Gameboy modu) + gerçek oyun kolu + klavyeyle menü gezintisi.
   Legend Heads'in kumanda.js'inden kopyalandı (sıfırdan yazılmadı); düzen Tamga Yolu'ndaki gibi:
   maç ekranı en üstte tam genişlikte, kumanda altta kalan alanın ortasında.
   - Ayarlar → KONTROL → "🎮 Klasik kumanda". Varsayılan: dokunmatik çubuk.
   - Maçta: yön haçı 8 yönde koşturur (çaprazlar dahil), A şut, B pas (basılı tutunca güç dolar, dokunmatikteki gibi), MENÜ mola.
   - Oyun kolu (Bluetooth PS/Xbox, standart düzen): sol çubuk analog koşu, ✕/A pas, ○/B şut, Start mola. Her modda çalışır.
   - Menülerde: yön tuşları düğmeler arasında gezer, A basar, B geri, MENÜ moladan çıkar.
   Bir Mr. Anduv! yapımıdır. */
(() => {
  'use strict';
  if (window.__kmKumanda) return;
  const $ = (s) => document.querySelector(s);
  const KUM = window.__kmKum = { x: 0, y: 0 };
  const gbAcik = () => { try { return S && S.set && S.set.kumanda === 1; } catch (e) { return false; } };

  const YON = ['yukari', 'asagi', 'sol', 'sag'];
  const TUSLAR = [...YON, 'a', 'b', 'menu'];
  const kaynak = { pad: {}, klavye: {}, kol: {} };
  let onceki = {}, odak = null, kumandaIzi = false, kolEksen = { x: 0, y: 0 };

  /* ---------- hangi ekrandayız ---------- */
  const gorunur = (el) => !!el && !el.hidden && el.getClientRects().length > 0 && el.getBoundingClientRect().width > 0;
  const macta = () => { const g = $('#game'); return !!g && !g.hidden; };
  function aktifKap() {
    const pm = $('#pmenu');
    if (macta()) return gorunur(pm) ? pm : null;
    return $('#app');
  }
  const dugmeler = (kap) => [...kap.querySelectorAll('button:not([disabled])')].filter(gorunur);
  const VARSAYILAN = '[data-g=go],[data-g=resume],button.big,button.primary,button:not(.back)';
  function varsayilan(kap) {
    const l = dugmeler(kap);
    for (const s of VARSAYILAN.split(',')) { const b = l.find((x) => x.matches(s)); if (b) return b; }
    return l[0] || null;
  }
  function geriDugmesi(kap) {
    const l = dugmeler(kap);
    if (kap.id === 'pmenu') return l.find((x) => x.matches('[data-g=resume],[data-g=pback],[data-g=go]')) || null;
    return l.find((x) => x.matches('.back')) || null;
  }

  /* ---------- odak ---------- */
  function odakla(b) {
    document.querySelectorAll('.km-odak').forEach((x) => x.classList.remove('km-odak'));
    odak = b;
    if (b && kumandaIzi) { b.classList.add('km-odak'); try { b.scrollIntoView({ block: 'nearest', inline: 'nearest' }); } catch (e) { /* */ } }
  }
  function odakTasi(kap, yon) {
    const l = dugmeler(kap);
    if (!odak || !l.includes(odak)) return odakla(varsayilan(kap));
    const r0 = odak.getBoundingClientRect(), x0 = r0.left + r0.width / 2, y0 = r0.top + r0.height / 2;
    let en = null, enP = Infinity;
    for (const b of l) {
      if (b === odak) continue;
      const r = b.getBoundingClientRect(), dx = r.left + r.width / 2 - x0, dy = r.top + r.height / 2 - y0;
      const ana = yon === 'sag' ? dx : yon === 'sol' ? -dx : yon === 'asagi' ? dy : -dy;
      const yan = yon === 'sag' || yon === 'sol' ? Math.abs(dy) : Math.abs(dx);
      if (ana <= 4) continue;
      const p = ana + yan * 2.2;
      if (p < enP) { enP = p; en = b; }
    }
    if (en) odakla(en);
  }

  /* ---------- basışlar ---------- */
  // maçta A = şut, B = pas; dokunmatik düğmelerdeki gibi basılı tutunca güç dolar (dolumBasla / dolumBitir)
  const MAC_TUS = { a: 'sut', b: 'pas' };
  function macBas(t, v) {
    const k = MAC_TUS[t]; if (!k) return;
    try { if (v) { SND.init(); dolumBasla(k); } else dolumBitir(k); } catch (e) { /* */ }
    const el = $(k === 'pas' ? '#bPas' : '#bSut'); if (el) el.classList.toggle('dn', v);
  }
  function olay(t, v) {
    const kap = aktifKap();
    if (!kap) {                                   // maç sürüyor
      if (t === 'menu' && v) { try { togglePause(); } catch (e) { /* */ } return; }
      macBas(t, v); return;
    }
    if (!v) return;
    if (YON.includes(t)) return odakTasi(kap, t);
    if (t === 'a') {
      if (!odak || !dugmeler(kap).includes(odak)) return odakla(varsayilan(kap));
      odak.click(); return;
    }
    if (t === 'b' || t === 'menu') { const g = geriDugmesi(kap); if (g) g.click(); }
  }
  function bas(k, t, v) {
    if (!!kaynak[k][t] === v) return;
    kaynak[k][t] = v;
    if (v) kumandaIzi = true;
    if (v && k === 'pad' && navigator.vibrate) try { navigator.vibrate(8); } catch (e) { /* */ }
  }

  /* ---------- klavye: yalnız menülerde (maç içi tuşlar index.html'de) ---------- */
  const KLAVYE = {
    ArrowUp: 'yukari', KeyW: 'yukari', ArrowDown: 'asagi', KeyS: 'asagi', ArrowLeft: 'sol', KeyA: 'sol', ArrowRight: 'sag', KeyD: 'sag',
    Enter: 'a', NumpadEnter: 'a', Space: 'a', KeyZ: 'a', KeyX: 'b', Backspace: 'b', Escape: 'b',
  };
  addEventListener('keydown', (e) => {
    const t = KLAVYE[e.code]; if (!t) return;
    const kap = aktifKap(); if (!kap) return;
    if (e.target.closest?.('input,textarea,select')) return;
    e.preventDefault(); e.stopImmediatePropagation();
    if (!e.repeat) bas('klavye', t, true);
  }, true);
  addEventListener('keyup', (e) => {
    const t = KLAVYE[e.code]; if (!t) return;
    if (aktifKap()) e.preventDefault();
    bas('klavye', t, false);
  }, true);
  addEventListener('blur', () => { for (const k in kaynak) for (const t in kaynak[k]) kaynak[k][t] = false; });

  /* ---------- gerçek oyun kolu (Gamepad API, standart düzen) ---------- */
  function kolOku() {
    const kollar = navigator.getGamepads ? [...navigator.getGamepads()].filter(Boolean) : [];
    if (!kollar.length) { kolEksen = { x: 0, y: 0 }; return; }
    const k = kollar[0], b = (i) => !!k.buttons[i]?.pressed, ax = k.axes[0] || 0, ay = k.axes[1] || 0;
    kolEksen = Math.hypot(ax, ay) > 0.2 ? { x: ax, y: ay } : { x: 0, y: 0 };
    const d = {
      yukari: b(12) || ay < -0.5, asagi: b(13) || ay > 0.5, sol: b(14) || ax < -0.5, sag: b(15) || ax > 0.5,
      b: b(0) || b(2), a: b(1) || b(3) || b(7), menu: b(9) || b(8),   // ✕/A pas · ○/B şut (futbol oyunlarındaki alışkanlık)
    };
    for (const [t, v] of Object.entries(d)) bas('kol', t, v);
  }

  /* ---------- ana döngü ---------- */
  function dongu() {
    try { kolOku(); } catch (e) { /* */ }
    const tut = {};
    for (const t of TUSLAR) tut[t] = !!(kaynak.pad[t] || kaynak.klavye[t] || kaynak.kol[t]);
    for (const t of TUSLAR) if (!!tut[t] !== !!onceki[t]) olay(t, tut[t]);
    onceki = tut;
    // maçta koşu yönü: oyun kolunun analog çubuğu, yoksa yön haçı (8 yön)
    const h = (t) => !!(kaynak.pad[t] || kaynak.kol[t]);
    if (!aktifKap()) {
      if (kolEksen.x || kolEksen.y) { KUM.x = kolEksen.x; KUM.y = kolEksen.y; }
      else { let x = (h('sag') ? 1 : 0) - (h('sol') ? 1 : 0), y = (h('asagi') ? 1 : 0) - (h('yukari') ? 1 : 0); const d = Math.hypot(x, y) || 1; KUM.x = x / d; KUM.y = y / d; }
    } else { KUM.x = 0; KUM.y = 0; }
    if (gbAcik()) kumandaIzi = true;              // klasik kumanda açıkken odak çerçevesi hep görünür
    const kap = aktifKap();
    if (kap && kumandaIzi) { if (!odak || !odak.isConnected || !dugmeler(kap).includes(odak)) odakla(varsayilan(kap)); else if (!odak.classList.contains('km-odak')) odakla(odak); }
    else if (!kap && odak) odakla(null);
    // klasik kumanda açık/kapalı ya da maç başladı/bitti: kabuk ve yerleşim
    const durum = (gbAcik() ? 1 : 0) + (macta() ? 2 : 0);
    if (durum !== sonDurum) { sonDurum = durum; kabukUygula(); }
    requestAnimationFrame(dongu);
  }
  let sonDurum = -1;

  /* ---------- kabuk (Kaptan Mecit: yeşil saha, lacivert, altın) ---------- */
  function stil() {
    const s = document.createElement('style');
    s.textContent = `
    .km-odak{outline:3px solid var(--gold)!important;outline-offset:3px;box-shadow:0 0 0 7px #000a!important}
    body.km-gb #game{--safe-t:0px;--safe-b:0px;border:3px solid var(--gold);border-radius:10px;box-shadow:0 0 0 4px var(--navy-d),0 8px 30px #000a}
    body.km-gb #game .btns,body.km-gb #game .joyhint,body.km-gb #game .ctl,body.km-gb #game .kbhint{display:none!important}
    .km-kabuk{position:fixed;inset:0;z-index:49;touch-action:none;-webkit-user-select:none;user-select:none;overflow:hidden;
      background:repeating-linear-gradient(90deg,rgba(255,255,255,.035) 0 26px,transparent 26px 52px),linear-gradient(180deg,var(--navy-d),#0b1626)}
    .km-kabuk[hidden]{display:none}
    .km-ad{position:absolute;color:var(--gold);font:10px var(--f-px,monospace);letter-spacing:3px;white-space:nowrap;opacity:.85;pointer-events:none}
    .km-imza{position:absolute;color:var(--gold);opacity:.7;font:8px var(--f-px,monospace);white-space:nowrap;pointer-events:none}
    .km-hac{position:absolute;width:126px;height:126px}
    .km-hac i{position:absolute;background:#0b1626;border:2px solid var(--gold-d);box-sizing:border-box}
    .km-hac i.d{left:42px;top:0;width:42px;height:126px;border-radius:8px}
    .km-hac i.y{left:0;top:42px;width:126px;height:42px;border-radius:8px}
    .km-hac i.m{left:44px;top:44px;width:38px;height:38px;border:0;border-radius:0}
    .km-hac b{position:absolute;width:0;height:0;border:8px solid transparent;opacity:.9}
    .km-hac .b1{left:55px;top:9px;border-bottom-color:var(--gold)}.km-hac .b2{left:55px;bottom:9px;border-top-color:var(--gold)}
    .km-hac .b3{left:9px;top:55px;border-right-color:var(--gold)}.km-hac .b4{right:9px;top:55px;border-left-color:var(--gold)}
    .km-hac.on-yukari .b1{border-bottom-color:#fff}.km-hac.on-asagi .b2{border-top-color:#fff}.km-hac.on-sol .b3{border-right-color:#fff}.km-hac.on-sag .b4{border-left-color:#fff}
    .km-dug{position:absolute;width:64px;height:64px;border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;
      font:16px var(--f-px,monospace);color:#fff;border:3px solid #fff;box-shadow:0 4px 0 #0009}
    .km-dug small{font-size:7px;margin-top:4px;letter-spacing:1px}
    .km-dug.a{background:radial-gradient(circle at 35% 30%,#e8584c,var(--red) 60%,var(--red-d))}
    .km-dug.b{background:radial-gradient(circle at 35% 30%,#4f86cc,var(--navy) 60%,var(--navy-d))}
    .km-dug.bas{transform:translateY(3px);box-shadow:0 1px 0 #0009}
    .km-menu{position:absolute;padding:8px 18px;border-radius:14px;background:var(--grass-d);border:2px solid var(--gold-d);color:var(--gold);
      font:8px var(--f-px,monospace);letter-spacing:1px;box-shadow:0 3px 0 #0009}
    .km-menu.bas{transform:translateY(2px);box-shadow:0 1px 0 #0009}`;
    document.head.appendChild(s);
  }
  let kabuk = null;
  function kabukKur() {
    const k = document.createElement('div');
    k.className = 'km-kabuk'; k.setAttribute('aria-label', 'Klasik kumanda');
    k.innerHTML = `<div class="km-ad">KAPTAN MECİT</div>
      <div class="km-hac"><i class="d"></i><i class="y"></i><i class="m"></i><b class="b1"></b><b class="b2"></b><b class="b3"></b><b class="b4"></b></div>
      <div class="km-dug b" data-t="b">B<small>PAS</small></div>
      <div class="km-dug a" data-t="a">A<small>ŞUT</small></div>
      <div class="km-menu" data-t="menu">MENÜ</div>
      <div class="km-imza">Bir Mr. Anduv! yapımıdır.</div>`;
    const hac = k.querySelector('.km-hac');
    const hacYaz = (e) => {
      const r = hac.getBoundingClientRect(), x = e.clientX - (r.left + r.width / 2), y = e.clientY - (r.top + r.height / 2);
      const o = Math.hypot(x, y) > 12;
      const d = { yukari: o && y < -Math.abs(x) * 0.45, asagi: o && y > Math.abs(x) * 0.45, sol: o && x < -Math.abs(y) * 0.45, sag: o && x > Math.abs(y) * 0.45 };
      for (const [t, v] of Object.entries(d)) bas('pad', t, v);
      hac.className = 'km-hac ' + Object.keys(d).filter((t) => d[t]).map((t) => 'on-' + t).join(' ');
    };
    const hacBirak = () => { for (const t of YON) bas('pad', t, false); hac.className = 'km-hac'; };
    hac.addEventListener('pointerdown', (e) => { e.preventDefault(); try { SND.init(); } catch (_) { /* */ } try { hac.setPointerCapture(e.pointerId); } catch (_) { /* */ } hacYaz(e); });
    hac.addEventListener('pointermove', (e) => { if (hac.hasPointerCapture?.(e.pointerId)) hacYaz(e); });
    ['pointerup', 'pointercancel', 'lostpointercapture'].forEach((ev) => hac.addEventListener(ev, hacBirak));
    k.querySelectorAll('.km-dug,.km-menu').forEach((d) => {
      const t = d.dataset.t;
      d.addEventListener('pointerdown', (e) => { e.preventDefault(); try { d.setPointerCapture(e.pointerId); } catch (_) { /* */ } d.classList.add('bas'); bas('pad', t, true); });
      ['pointerup', 'pointercancel', 'lostpointercapture'].forEach((ev) => d.addEventListener(ev, () => { d.classList.remove('bas'); bas('pad', t, false); }));
    });
    k.addEventListener('contextmenu', (e) => e.preventDefault());
    document.body.appendChild(k);
    return k;
  }

  /* ---------- yerleşim: JS ile piksel piksel (iPhone'da vh/cqw/dolguya güvenmeden) ---------- */
  let prob = null;
  function guvenli() {
    if (!prob) {
      prob = document.createElement('div');
      prob.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;pointer-events:none;' +
        'padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
      document.body.appendChild(prob);
    }
    const c = getComputedStyle(prob), n = (v) => parseFloat(v) || 0;
    return { ust: n(c.paddingTop), sag: n(c.paddingRight), alt: n(c.paddingBottom), sol: n(c.paddingLeft) };
  }
  const yer = (el, o) => { for (const p of ['left', 'right', 'top', 'bottom', 'transform']) el.style[p] = o[p] ?? ''; };
  function yerles() {
    const g = $('#game'); if (!g) return;
    const acik = gbAcik() && macta();
    document.body.classList.toggle('km-gb', acik);
    if (kabuk) kabuk.hidden = !acik;
    if (!acik) { for (const p of ['left', 'top', 'width', 'height', 'right', 'bottom']) g.style[p] = ''; yenile(); return; }
    if (!kabuk) kabuk = kabukKur();
    const vw = innerWidth, vh = innerHeight, s = guvenli(), q = (x) => kabuk.querySelector(x);
    const hac = q('.km-hac'), A = q('.km-dug.a'), B = q('.km-dug.b'), ad = q('.km-ad'), menu = q('.km-menu'), imza = q('.km-imza');
    if (vh >= vw) {
      // Tamga Yolu düzeni: maç ekranı en üstte tam genişlikte, kumanda (≈230 px) altta kalan alanın ortasında
      const KG = 230, ust = s.ust + 8, gw = vw - 16 - s.sol - s.sag;
      const gh = Math.max(200, vh - ust - s.alt - KG - 18);
      Object.assign(g.style, { left: 8 + s.sol + 'px', top: ust + 'px', width: gw + 'px', height: gh + 'px', right: 'auto', bottom: 'auto' });
      const P = ust + gh + Math.max(8, Math.round((vh - s.alt - (ust + gh) - KG) / 2));
      yer(ad, { left: '50%', top: P + 2 + 'px', transform: 'translateX(-50%)' });
      yer(hac, { left: 22 + s.sol + 'px', top: P + 24 + 'px' });
      yer(A, { right: 22 + s.sag + 'px', top: P + 22 + 'px' });
      yer(B, { right: 96 + s.sag + 'px', top: P + 64 + 'px' });
      yer(menu, { left: '50%', top: P + 172 + 'px', transform: 'translateX(-50%)' });
      yer(imza, { left: '50%', top: P + 212 + 'px', transform: 'translateX(-50%)' });
    } else {
      const S = Math.round(Math.min(180, Math.max(150, vw * 0.18))), sol = S + s.sol, sag = S + s.sag;
      const ust = Math.max(6, s.ust), gh = vh - ust - Math.max(6, s.alt), gw = vw - sol - sag;
      Object.assign(g.style, { left: sol + 'px', top: ust + 'px', width: gw + 'px', height: gh + 'px', right: 'auto', bottom: 'auto' });
      const ort = vh / 2;
      yer(ad, { left: s.sol + S / 2 + 'px', top: Math.max(10, s.ust + 6) + 'px', transform: 'translateX(-50%)' });
      yer(hac, { left: s.sol + (S - 126) / 2 + 'px', top: ort - 63 + 'px' });
      yer(A, { right: s.sag + 10 + 'px', top: ort - 78 + 'px' });
      yer(B, { right: s.sag + S - 76 + 'px', top: ort - 8 + 'px' });
      yer(menu, { left: s.sol + S / 2 + 'px', bottom: Math.max(10, s.alt + 6) + 'px', transform: 'translateX(-50%)' });
      yer(imza, { right: s.sag + S / 2 + 'px', bottom: Math.max(12, s.alt + 8) + 'px', transform: 'translateX(50%)' });
    }
    yenile();
  }
  // oyunun kendi yeniden boyutlanması (#game kutusunun ölçüsünü okur: oyunW/oyunH)
  function yenile() { try { if (typeof M !== 'undefined' && M) resize(); } catch (e) { /* */ } }
  function kabukUygula() { yerles(); requestAnimationFrame(yerles); [80, 300, 700].forEach((t) => setTimeout(yerles, t)); }

  addEventListener('pointerdown', (e) => {
    if ((gbAcik() && macta()) || e.target.closest?.('.km-kabuk')) return;
    kumandaIzi = false; odakla(null);
  }, true);
  addEventListener('gamepadconnected', () => { kumandaIzi = true; });
  addEventListener('resize', () => { if (gbAcik() && macta()) kabukUygula(); });
  addEventListener('orientationchange', () => { if (gbAcik() && macta()) kabukUygula(); });

  window.__kmKumanda = { bas, kaynak, acik: gbAcik };   // test için
  stil(); requestAnimationFrame(dongu);
})();
