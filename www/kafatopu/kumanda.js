/* Legend Heads · Klasik kumanda (Gameboy modu) + gerçek oyun kumandası + klavyeyle menü gezintisi.
   Kurt Yolu'ndaki kumanda.js ile aynı yaklaşım, Legend Heads'in kendi atari kabuğuyla:
   - Ayarlar → "Klasik kumanda" açılınca telefon dikken ekranın altına, yan çevrilince iki yanına kumanda gelir.
   - Maçta: ◀︎ ▶︎ koş, ▲ ya da B zıpla, A vur, A+B ya da ▼ süper, MENÜ mola.
   - Menülerde: yön tuşları düğmeler arasında gezer, A basar, B geri döner, MENÜ moladan çıkar.
   - Bluetooth/USB oyun kumandası (standart düzen) ve klavye de aynı şekilde çalışır.
   Ayar yalnız bu cihazda saklanır (lh-kumanda). Varsayılan: kapalı. Bir Mr. Anduv! yapımıdır. */
(() => {
  'use strict';
  const LH = window.__LH, KUM = window.__lhKum;
  if (!LH || !KUM || window.__lhKumanda) return;
  const $ = (id) => document.getElementById(id);
  const ANAHTAR = 'lh-kumanda';
  let gbAcik = false;
  try { gbAcik = !!JSON.parse(localStorage.getItem(ANAHTAR) || '{}').gb; } catch (e) { /* */ }

  const YON = ['yukari', 'asagi', 'sol', 'sag'];
  const TUSLAR = [...YON, 'a', 'b', 'x', 'menu'];
  const kaynak = { pad: {}, klavye: {}, kol: {} };
  let onceki = {}, odak = null, kumandaIzi = false;

  /* ---------- hangi ekrandayız: açık ipucu kartı, açık perde (menü) ya da maç ---------- */
  const gorunur = (el) => !!el && !el.hidden && el.offsetParent !== null && el.getBoundingClientRect().width > 0;
  function aktifKap() {
    const rh = $('rh');
    if (gorunur(rh) && rh.querySelector('button')) return rh;
    const ovler = [...document.querySelectorAll('.stage .ov')].filter((o) => !o.hidden);
    return ovler.pop() || null;
  }
  const dugmeler = (kap) => [...kap.querySelectorAll('button:not([disabled])')].filter(gorunur);
  const VARSAYILAN = '#resumeBtn,#playBtn,#hOk,#sNo,#aOk,[data-rh=ok],#endBtns .btn,.chip:not([disabled]),.btn';
  function varsayilan(kap) {
    const l = dugmeler(kap);
    for (const s of VARSAYILAN.split(',')) { const b = l.find((x) => x.matches(s)); if (b) return b; }
    return l[0] || null;
  }
  // B / MENÜ: her perdede "geri" sayılan düğme
  const GERI = { rh: '[data-rh=ok]', pauseOv: '#resumeBtn', setOv: '#sNo,#aOk', howOv: '#hOk', mapOv: '#homeBtn' };
  function geriDugmesi(kap) {
    const l = dugmeler(kap), s = GERI[kap.id];
    if (s) for (const q of s.split(',')) { const b = l.find((x) => x.matches(q)); if (b) return b; }
    if (kap.id === 'endOv') return l.find((x) => /harita/i.test(x.textContent)) || null;
    return null;
  }

  /* ---------- odak ---------- */
  function odakla(b) {
    document.querySelectorAll('.lh-odak').forEach((x) => x.classList.remove('lh-odak'));
    odak = b;
    if (b && kumandaIzi) { b.classList.add('lh-odak'); try { b.scrollIntoView({ block: 'nearest', inline: 'nearest' }); } catch (e) { /* */ } }
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
  function olay(t) {
    const kap = aktifKap();
    if (!kap) {                                   // maç sürüyor: hareketi dongu() akıtır, burada yalnız MENÜ
      if (t === 'menu' && LH.live() && !LH.durdu()) LH.pause();
      return;
    }
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
    if (v && k !== 'pad') kumandaIzi = true;
    if (v && k === 'pad') { kumandaIzi = true; if (navigator.vibrate) try { navigator.vibrate(8); } catch (e) { /* */ } }
  }

  /* ---------- klavye: yalnız menülerde (maç içi tuşlar index.html'de) ---------- */
  const KLAVYE = {
    ArrowUp: 'yukari', KeyW: 'yukari', ArrowDown: 'asagi', KeyS: 'asagi', ArrowLeft: 'sol', KeyA: 'sol', ArrowRight: 'sag', KeyD: 'sag',
    Enter: 'a', NumpadEnter: 'a', Space: 'a', KeyZ: 'a', KeyX: 'b', Backspace: 'b', Escape: 'b', KeyP: 'menu',
  };
  addEventListener('keydown', (e) => {
    const t = KLAVYE[e.code]; if (!t) return;
    if (!aktifKap()) { if (t === 'menu') { bas('klavye', 'menu', true); } return; }
    e.preventDefault(); e.stopImmediatePropagation();   // menüdeyken maç tuşları ve Esc'in mola işi çalışmasın
    if (!e.repeat) bas('klavye', t, true);
  }, true);
  addEventListener('keyup', (e) => {
    const t = KLAVYE[e.code]; if (!t) return;
    if (aktifKap()) e.preventDefault();               // odaklı düğmeye Boşluk'la ikinci kez basılmasın
    bas('klavye', t, false);
  }, true);
  addEventListener('blur', () => { for (const k in kaynak) for (const t in kaynak[k]) kaynak[k][t] = false; });

  /* ---------- gerçek kumanda (Gamepad API, standart düzen) ---------- */
  function kolOku() {
    const kollar = navigator.getGamepads ? [...navigator.getGamepads()].filter(Boolean) : [];
    if (!kollar.length) return;
    const k = kollar[0], b = (i) => !!k.buttons[i]?.pressed, ax = k.axes[0] || 0, ay = k.axes[1] || 0;
    const d = {
      yukari: b(12) || ay < -0.5, asagi: b(13) || ay > 0.5, sol: b(14) || ax < -0.5, sag: b(15) || ax > 0.5,
      a: b(0), b: b(1), x: b(2) || b(3) || b(5) || b(7), menu: b(9) || b(8),
    };
    for (const [t, v] of Object.entries(d)) bas('kol', t, v);
  }

  /* ---------- ana döngü ---------- */
  function dongu() {
    try { kolOku(); } catch (e) { /* */ }
    const tut = {};
    for (const t of TUSLAR) tut[t] = !!(kaynak.pad[t] || kaynak.klavye[t] || kaynak.kol[t]);
    for (const t of TUSLAR) if (tut[t] && !onceki[t]) olay(t);
    onceki = tut;
    // maç içi: ekrandaki kumanda ve gerçek kumanda oyunun girişine akar (klavye zaten index.html'de)
    const p = kaynak.pad, k = kaynak.kol, h = (t) => !!(p[t] || k[t]);
    const mac = !aktifKap();
    KUM.left = mac && h('sol');
    KUM.right = mac && h('sag');
    KUM.jump = mac && (h('yukari') || h('b'));
    KUM.kick = mac && h('a');
    KUM.super = mac && (h('asagi') || h('x') || (h('a') && h('b')));
    // menüdeyken odak düğmesi kaybolduysa (ekran yeniden çizildi) varsayılana dön
    const kap = aktifKap();
    if (kap && kumandaIzi) { if (!odak || !odak.isConnected || !dugmeler(kap).includes(odak)) odakla(varsayilan(kap)); else if (!odak.classList.contains('lh-odak')) odakla(odak); }
    else if (!kap && odak) odakla(null);
    requestAnimationFrame(dongu);
  }

  /* ---------- atari kabuğu ---------- */
  function stil() {
    const s = document.createElement('style'); s.id = 'lh-kum-stil';
    s.textContent = `
    .lh-odak{outline:3px solid var(--teal)!important;outline-offset:3px;box-shadow:0 0 0 7px color-mix(in srgb,var(--ink) 75%,transparent)!important}
    body.lh-gb .pad{display:none!important}
    body.lh-gb #app{z-index:1;pointer-events:none}
    body.lh-gb #app .stage{pointer-events:auto}
    body.lh-gb{background:#1b0d3d}
    .lh-kabuk{position:fixed;inset:0;z-index:0;touch-action:none;-webkit-user-select:none;user-select:none;overflow:hidden;
      background:
        radial-gradient(circle at 20% 30%,rgba(255,201,60,.10) 0 2px,transparent 3px) 0 0/34px 34px,
        radial-gradient(circle at 70% 80%,rgba(31,214,196,.10) 0 2px,transparent 3px) 0 0/46px 46px,
        linear-gradient(160deg,#3a1a72,#24104d 55%,#1b0d3d)}
    .lh-kabuk[hidden]{display:none}
    .lh-kabuk .alan{position:absolute;pointer-events:none}
    .lh-ad{position:absolute;color:var(--sun);font:400 15px var(--f-display);letter-spacing:3px;white-space:nowrap;
      text-shadow:2px 2px 0 var(--magenta);opacity:.85;pointer-events:none}
    .lh-imza{position:absolute;color:var(--sun);opacity:.7;font:700 10px var(--f-body);white-space:nowrap;pointer-events:none}
    .lh-hac{position:absolute;width:144px;height:144px}
    .lh-hac i{position:absolute;background:#140a2e;border:2px solid var(--magenta);box-sizing:border-box}
    .lh-hac i.d{left:48px;top:0;width:48px;height:144px;border-radius:10px}
    .lh-hac i.y{left:0;top:48px;width:144px;height:48px;border-radius:10px}
    .lh-hac i.m{left:50px;top:50px;width:44px;height:44px;border:0;border-radius:0;background:#140a2e}
    .lh-hac b{position:absolute;width:0;height:0;border:8px solid transparent;opacity:.85}
    .lh-hac .b1{border-bottom-color:var(--cream)}.lh-hac .b2{border-top-color:var(--cream)}.lh-hac .b3{border-right-color:var(--cream)}.lh-hac .b4{border-left-color:var(--cream)}
    .lh-hac .b1{left:65px;top:13px}.lh-hac .b2{left:65px;bottom:13px}.lh-hac .b3{left:12px;top:64px}.lh-hac .b4{right:12px;top:64px}
    .lh-hac.on-yukari .b1{border-bottom-color:var(--sun);opacity:1}.lh-hac.on-asagi .b2{border-top-color:var(--sun);opacity:1}.lh-hac.on-sol .b3{border-right-color:var(--sun);opacity:1}.lh-hac.on-sag .b4{border-left-color:var(--sun);opacity:1}
    .lh-hac small{position:absolute;font:800 9px var(--f-body);letter-spacing:1px;color:var(--teal);white-space:nowrap}
    .lh-hac .e1{left:50%;top:-16px;transform:translateX(-50%)}.lh-hac .e2{left:50%;bottom:-16px;transform:translateX(-50%)}
    .lh-dug{position:absolute;width:72px;height:72px;border-radius:50%;display:flex;flex-direction:column;align-items:center;justify-content:center;
      font:400 26px/1 var(--f-display);color:var(--ink);border:3px solid var(--ink);box-shadow:0 5px 0 var(--ink),0 0 0 3px rgba(255,255,255,.08)}
    .lh-dug small{font:800 9px var(--f-body);letter-spacing:1px;margin-top:2px}
    .lh-dug.a{background:radial-gradient(circle at 35% 30%,#7ff3e8,var(--teal) 60%)}
    .lh-dug.b{background:radial-gradient(circle at 35% 30%,#ffe7a3,var(--sun) 60%)}
    .lh-dug.bas{transform:translateY(4px);box-shadow:0 1px 0 var(--ink)}
    .lh-menu{position:absolute;padding:7px 20px;border-radius:999px;background:var(--magenta);color:var(--cream);border:2px solid var(--ink);
      font:400 12px var(--f-display);letter-spacing:2px;box-shadow:0 4px 0 var(--ink)}
    .lh-menu.bas{transform:translateY(3px);box-shadow:0 1px 0 var(--ink)}
    .lh-dondur{position:fixed;inset:0;z-index:50;display:flex;flex-direction:column;align-items:center;justify-content:center;gap:14px;padding:24px;text-align:center;
      background:linear-gradient(160deg,#3a1a72,#1b0d3d);color:var(--cream);font:700 16px var(--f-body)}
    .lh-dondur[hidden]{display:none}
    .lh-dondur .ik{font-size:64px;line-height:1;animation:lhDon 2.4s ease-in-out infinite}
    @keyframes lhDon{0%,30%{transform:rotate(0)}60%,100%{transform:rotate(90deg)}}
    .lh-dondur h2{margin:0;font:400 24px var(--f-display);color:var(--sun);text-shadow:2px 2px 0 var(--magenta)}
    .lh-dondur p{margin:0;opacity:.85;max-width:300px}
    .lh-dondur button{margin-top:6px;font:400 15px var(--f-display);background:var(--teal);color:var(--ink);border:3px solid var(--ink);border-radius:999px;padding:12px 22px;box-shadow:0 5px 0 var(--ink)}
    .lh-kabuk.kucuk .lh-hac{width:120px;height:120px}
    .lh-kabuk.kucuk .lh-hac i.d{left:40px;width:40px;height:120px}
    .lh-kabuk.kucuk .lh-hac i.y{top:40px;width:120px;height:40px}
    .lh-kabuk.kucuk .lh-hac i.m{left:42px;top:42px;width:36px;height:36px}
    .lh-kabuk.kucuk .lh-hac .b1{left:53px;top:10px}.lh-kabuk.kucuk .lh-hac .b2{left:53px;bottom:10px}
    .lh-kabuk.kucuk .lh-hac .b3{left:10px;top:52px}.lh-kabuk.kucuk .lh-hac .b4{right:10px;top:52px}
    .lh-kabuk.kucuk .lh-dug{width:62px;height:62px;font-size:22px}
    .lh-kabuk.kucuk .lh-menu{padding:6px 18px;font-size:11px}
    .lh-ipucu{position:absolute;color:var(--cream);opacity:.55;font:700 10px var(--f-body);white-space:nowrap;pointer-events:none}`;
    document.head.appendChild(s);
  }
  let kabuk = null;
  function kabukKur() {
    const k = document.createElement('div');
    k.className = 'lh-kabuk'; k.setAttribute('aria-label', 'Klasik kumanda');
    k.innerHTML = `<div class="lh-ad">LEGEND HEADS</div>
      <div class="lh-hac" data-t="hac"><i class="d"></i><i class="y"></i><i class="m"></i>
        <b class="b1"></b><b class="b2"></b><b class="b3"></b><b class="b4"></b>
        <small class="e1">ZIPLA</small><small class="e2">SÜPER</small></div>
      <div class="lh-dug b" data-t="b">B<small>ZIPLA</small></div>
      <div class="lh-dug a" data-t="a">A<small>VUR</small></div>
      <div class="lh-ipucu">A + B = SÜPER</div>
      <div class="lh-menu" data-t="menu">MENÜ</div>
      <div class="lh-imza">Bir Mr. Anduv! yapımıdır.</div>`;
    const hac = k.querySelector('.lh-hac');
    const hacYaz = (e) => {
      const r = hac.getBoundingClientRect(), x = e.clientX - (r.left + r.width / 2), y = e.clientY - (r.top + r.height / 2);
      const o = Math.hypot(x, y) > 14;
      const d = { yukari: o && y < -Math.abs(x) * 0.5, asagi: o && y > Math.abs(x) * 0.5, sol: o && x < -Math.abs(y) * 0.5, sag: o && x > Math.abs(y) * 0.5 };
      for (const [t, v] of Object.entries(d)) bas('pad', t, v);
      hac.className = 'lh-hac ' + Object.keys(d).filter((t) => d[t]).map((t) => 'on-' + t).join(' ');
    };
    const hacBirak = () => { for (const t of YON) bas('pad', t, false); hac.className = 'lh-hac'; };
    hac.addEventListener('pointerdown', (e) => { e.preventDefault(); try { hac.setPointerCapture(e.pointerId); } catch (_) { /* */ } hacYaz(e); });
    hac.addEventListener('pointermove', (e) => { if (hac.hasPointerCapture?.(e.pointerId)) hacYaz(e); });
    ['pointerup', 'pointercancel', 'lostpointercapture'].forEach((ev) => hac.addEventListener(ev, hacBirak));
    k.querySelectorAll('.lh-dug,.lh-menu').forEach((d) => {
      const t = d.dataset.t;
      d.addEventListener('pointerdown', (e) => { e.preventDefault(); try { d.setPointerCapture(e.pointerId); } catch (_) { /* */ } d.classList.add('bas'); bas('pad', t, true); });
      ['pointerup', 'pointercancel', 'lostpointercapture'].forEach((ev) => d.addEventListener(ev, () => { d.classList.remove('bas'); bas('pad', t, false); }));
    });
    k.addEventListener('contextmenu', (e) => e.preventDefault());
    document.body.appendChild(k);
    return k;
  }

  /* ---------- yerleşim: iPhone'da (WebKit) vh'ye güvenmeden, JS ile piksel piksel ----------
     Dik: oyun üstte, kumanda altta (Gameboy). Yan: oyun ortada, yön haçı solda, A/B sağda. */
  let prob = null;
  function guvenli() {
    if (!prob) {
      prob = document.createElement('div');
      prob.style.cssText = 'position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;pointer-events:none;' +
        'padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';
      document.body.appendChild(prob);
    }
    const c = getComputedStyle(prob), n = (v) => parseFloat(v) || 0;
    const g = { ust: n(c.paddingTop), sag: n(c.paddingRight), alt: n(c.paddingBottom), sol: n(c.paddingLeft) };
    // iPhone açılışın ilk anlarında güvenli alanı 0 bildirir: çerçeve saatin/TestFlight yazısının altına kayıyordu.
    // Ölçülen gerçek değer (dik ekran üstü) cihazda saklanır; 0 gelirse saklanan ya da güvenli bir tahmin kullanılır.
    const dik = innerHeight > innerWidth, ios = /iPhone|iPad|iPod/.test(navigator.userAgent) || window.Capacitor?.getPlatform?.() === 'ios';
    try {
      if (dik && g.ust > 0) localStorage.setItem('lh-guvenli-ust', String(g.ust));
      if (dik && g.ust === 0 && ios) { const k = parseFloat(localStorage.getItem('lh-guvenli-ust')); g.ust = k > 0 ? k : (screen.height >= 812 ? 60 : 20); g.tahmin = true; }
    } catch (e) { if (dik && g.ust === 0 && ios) { g.ust = 60; g.tahmin = true; } }
    return g;
  }
  const yer = (el, o) => { for (const p of ['left', 'right', 'top', 'bottom', 'transform']) el.style[p] = o[p] ?? ''; };
  // sahne boyu piksel olarak: iPhone'da kapsayıcı birimleri (cqw/cqh) dolguyu saymayıp sahneyi kumandanın üstüne taşırıyordu
  function sahne(st, w, h) {
    if (!st) return;
    const gw = Math.floor(Math.max(100, Math.min(w, h * 16 / 9))), gh = Math.floor(gw * 9 / 16);
    st.style.width = gw + 'px'; st.style.height = gh + 'px';
  }
  // telefon dikken ve klasik kumanda kapalıyken: "yan çevir ya da klasik kumandayı aç" perdesi
  let dondur = null;
  const dokunmatik = () => matchMedia('(pointer:coarse)').matches || !!window.Capacitor?.isNativePlatform?.();
  function dondurGuncelle(dik) {
    const goster = dik && !gbAcik && dokunmatik();
    if (goster && !dondur) {
      dondur = document.createElement('div'); dondur.className = 'lh-dondur';
      dondur.innerHTML = `<div class="ik">📱</div><h2>Telefonu yan çevir</h2><p>Maç sahası yatay ekrana göre. Dik tutarak oynamak istersen eski usul kumandayı aç: ekran üstte, tuşlar altta.</p>
        <button type="button">🎮 Klasik kumandayı aç</button><p style="font-size:12px;opacity:.6">Sonradan Ayarlar'dan kapatabilirsin.</p>`;
      dondur.querySelector('button').addEventListener('click', () => window.__lhKumanda.degistir());
      document.body.appendChild(dondur);
    }
    if (dondur) dondur.hidden = !goster;
    if (goster && LH.live() && !LH.durdu()) LH.pause();
  }
  function yerles() {
    dondurGuncelle(innerHeight > innerWidth);
    const app = $('app'); if (!app) return;
    const st = $('stage');
    if (!gbAcik) { app.style.padding = ''; app.style.alignItems = ''; if (st) { st.style.width = ''; st.style.height = ''; } return; }
    const vw = innerWidth, vh = innerHeight, g = guvenli(), q = (s) => kabuk.querySelector(s);
    const hac = q('.lh-hac'), A = q('.lh-dug.a'), B = q('.lh-dug.b'), ad = q('.lh-ad'), menu = q('.lh-menu'), imza = q('.lh-imza'), ip = q('.lh-ipucu');
    if (vh >= vw) {
      // dik: ekran + kumanda tek parça bir konsol gibi ortada; kumanda küçük ve ekranın hemen altında
      kabuk.classList.add('kucuk');
      const KG = 238, ARA = 46;                                  // kumanda yüksekliği, ekranla kumanda arası (logo)
      const sw = vw - 20 - g.sol - g.sag;
      // Tamga Yolu düzeni: ekran en üstte tam genişlikte, neredeyse kare (240:224); kumanda kalan alanın ortasında.
      // Sahne 16:9'dan uzun olduğu için oyun yakın kamerayla topu izler, karakterler büyük görünür.
      const ustB = g.ust + 10;
      // onaylı ölçü (Kurt Yolu 1.3.5): sahne kumandaya kadar bütün alanı doldurur, kamera izler; kumanda 1,15 kat
      const zH = 1.15;
      const sh = Math.floor(Math.max(sw * 9 / 16, vh - ustB - g.alt - ARA - KG * zH - 10));
      const kalan = vh - g.alt - (ustB + sh);
      // alt kısımda yer varsa tuşlar büyür (genişliğe sığdığı kadar): z = büyütme katsayısı
      const z = Math.max(1, Math.min(zH, (kalan - ARA - 8) / KG, (vw - g.sol - g.sag - 56) / 280));
      const bosluk = Math.max(0, Math.round((kalan - ARA - KG * z) / 2));
      const P = ustB + sh + bosluk + ARA;                                 // kumandanın üst kenarı
      app.style.alignItems = 'start';
      app.style.padding = `${ustB}px ${10 + g.sag}px ${Math.max(0, vh - ustB - sh)}px ${10 + g.sol}px`;
      st.style.width = sw + 'px'; st.style.height = sh + 'px';
      const sc = `scale(${z.toFixed(3)})`;
      hac.style.transformOrigin = '0 0'; A.style.transformOrigin = B.style.transformOrigin = ip.style.transformOrigin = '100% 0';
      yer(ad, { left: '50%', top: ustB + sh + bosluk + 12 + 'px', transform: 'translateX(-50%) scale(.85)' });
      yer(hac, { left: 22 + g.sol + 'px', top: P + 12 * z + 'px', transform: sc });
      yer(A, { right: 24 + g.sag + 'px', top: P + 8 * z + 'px', transform: sc });
      yer(B, { right: 24 + 74 * z + g.sag + 'px', top: P + 50 * z + 'px', transform: sc });
      yer(ip, { right: 34 + g.sag + 'px', top: P + 124 * z + 'px', transform: sc });
      yer(menu, { left: '50%', top: P + (166 * z) + 'px', transform: 'translateX(-50%) ' + sc });
      yer(imza, { left: '50%', top: P + 166 * z + 44 * z + 'px', transform: 'translateX(-50%)' });
    } else {
      kabuk.classList.remove('kucuk');
      for (const el of [hac, A, B, ip]) el.style.transformOrigin = '';
      const S = Math.round(Math.min(190, Math.max(152, vw * 0.18)));
      const sol = S + g.sol, sag = S + g.sag;
      app.style.alignItems = '';
      app.style.padding = `${Math.max(6, g.ust)}px ${sag}px ${Math.max(6, g.alt)}px ${sol}px`;
      sahne(st, vw - sol - sag - 8, vh - Math.max(6, g.ust) - Math.max(6, g.alt));
      const ort = vh / 2;
      yer(ad, { left: g.sol + S / 2 + 'px', top: Math.max(8, g.ust + 4) + 'px', transform: 'translateX(-50%) scale(.8)' });
      yer(hac, { left: g.sol + (S - 144) / 2 + 'px', top: ort - 72 + 'px' });
      yer(A, { right: g.sag + 12 + 'px', top: ort - 86 + 'px' });
      yer(B, { right: g.sag + S - 84 + 'px', top: ort - 12 + 'px' });
      yer(ip, { right: g.sag + S / 2 + 'px', top: ort + 78 + 'px', transform: 'translateX(50%)' });
      yer(menu, { left: g.sol + S / 2 + 'px', bottom: Math.max(10, g.alt + 6) + 'px', transform: 'translateX(-50%)' });
      yer(imza, { right: g.sag + S / 2 + 'px', bottom: Math.max(12, g.alt + 8) + 'px', transform: 'translateX(50%)' });
    }
  }
  function yerlesTekrar() { yerles(); requestAnimationFrame(yerles); [60, 250, 700, 1500, 3000].forEach((t) => setTimeout(yerles, t)); }
  function kabukUygula() {
    if (gbAcik) { if (!kabuk) kabuk = kabukKur(); kabuk.hidden = false; document.body.classList.add('lh-gb'); kumandaIzi = true; }
    else { if (kabuk) kabuk.hidden = true; document.body.classList.remove('lh-gb'); }
    yerlesTekrar();
  }

  // dokunmatiğe dönen oyuncu: odak çerçevesi gizlenir (klasik kumanda açıksa kalır)
  addEventListener('pointerdown', (e) => {
    if (gbAcik || e.target.closest?.('.lh-kabuk')) return;
    kumandaIzi = false; odakla(null);
  }, true);
  addEventListener('gamepadconnected', () => { kumandaIzi = true; });
  addEventListener('resize', yerlesTekrar);
  addEventListener('orientationchange', yerlesTekrar);
  window.visualViewport?.addEventListener('resize', yerlesTekrar);

  window.__lhKumanda = {
    acik: () => gbAcik,
    degistir() {
      gbAcik = !gbAcik;
      try { localStorage.setItem(ANAHTAR, JSON.stringify({ gb: gbAcik })); } catch (e) { /* */ }
      kabukUygula(); return gbAcik;
    },
    bas, kaynak,   // test için
  };
  stil(); kabukUygula(); requestAnimationFrame(dongu);
})();
