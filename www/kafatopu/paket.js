/* Mr. Anduv! ortak "test önerileri" paketi (Malazgirt Akıncıları 1.6 ve Champion Battle Manager 4.4 ile aynı yaklaşım):
   rehber ilerlemesi, uygulama içinden puan ver (yalnız iOS/Android), paylaş, "Bize yaz" (hazır e-posta), "Verilerimi sil".
   Hiçbir veri toplanmaz: puan ve paylaşım telefonun/mağazanın kendi ekranlarıyla yapılır, her şey cihazda kalır.
   Kullanım: const PK = MrAnduvPaket({ad, surum, onek, androidId, iosId, ipuclari, eskiMi, temel, paylasMetni, ilerleme, tost, koru}); */
(function () {
  'use strict';
  window.MrAnduvPaket = function (cfg) {
    const oku = (k, v) => { try { const r = localStorage.getItem(k); return r == null ? v : (JSON.parse(r) ?? v); } catch (e) { return v; } };
    const yaz = (k, v) => { try { localStorage.setItem(k, JSON.stringify(v)); } catch (e) { /* depolama yok */ } };
    const RKEY = cfg.onek + 'rehber', PKEY = cfg.onek + 'puan';
    const VITRIN = 'https://emreanduv.github.io/';

    const platform = () => { try { const p = window.Capacitor && window.Capacitor.getPlatform && window.Capacitor.getPlatform(); if (p && p !== 'web') return p; } catch (e) { /* */ } return 'web'; };
    const mobil = () => platform() === 'ios' || platform() === 'android';
    const magaza = () => {
      if (platform() === 'android' && cfg.androidId) return 'https://play.google.com/store/apps/details?id=' + cfg.androidId;
      if (platform() === 'ios' && cfg.iosId) return 'https://apps.apple.com/app/id' + cfg.iosId;
      return VITRIN;
    };

    /* ---- rehber ---- */
    const durum = () => { const d = oku(RKEY, null); return d && typeof d === 'object' ? Object.assign({ gor: {}, kapali: false }, d) : { gor: {}, kapali: false }; };
    const yeniMi = () => oku(RKEY, null) == null;
    const goruldu = (...k) => { const d = durum(); k.forEach(x => { d.gor[x] = 1; }); yaz(RKEY, d); };
    const kapat = () => { const d = durum(); d.kapali = true; yaz(RKEY, d); };
    const bastan = () => yaz(RKEY, { gor: {}, kapali: false });
    const gosterilsin = k => { const d = durum(); return !!cfg.ipuclari[k] && !d.kapali && !d.gor[k]; };
    /* eski oyuncu (ilerlemesi var, rehber ilk kez geliyor): temel ipuçlarını görülmüş say, zorla gösterme */
    if (yeniMi()) yaz(RKEY, { gor: cfg.eskiMi ? Object.fromEntries((cfg.temel || []).map(k => [k, 1])) : {}, kapali: false });

    /* ---- puan: olumlu anda en çok 2 kez sorulur, yenilgide asla; "Puan ver" ya da "Önerim var" sonrası bir daha sorulmaz ---- */
    const pd = () => Object.assign({ n: 0, tamam: false, son: null }, oku(PKEY, {}));
    const puanSorulsunMu = (esik, esikler) => { if (!mobil()) return false; const p = pd(); return !p.tamam && p.n < 2 && esikler.includes(esik) && p.son !== esik; };
    const puanSoruldu = esik => { const p = pd(); p.n++; p.son = esik; yaz(PKEY, p); };
    const puanTamam = () => { const p = pd(); p.tamam = true; yaz(PKEY, p); };
    const disAc = url => { try { const w = window.open(url, '_blank'); if (!w) location.href = url; } catch (e) { location.href = url; } };
    async function puanVer() {
      puanTamam();
      const R = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.InAppReview;
      try { if (R && R.requestReview) { await R.requestReview(); return; } } catch (e) { /* mağaza bağlantısına düş */ }
      disAc(magaza());
    }

    /* ---- paylaş: telefonun paylaşım menüsü, yoksa tarayıcınınki, yoksa panoya kopyala ---- */
    async function paylas(metin) {
      metin = metin || cfg.paylasMetni;
      const url = magaza(), P = window.Capacitor && window.Capacitor.Plugins && window.Capacitor.Plugins.Share;
      try {
        if (P && P.share) { await P.share({ title: cfg.ad, text: metin, url, dialogTitle: 'Arkadaşına öner' }); return; }
        if (navigator.share) { await navigator.share({ title: cfg.ad, text: metin, url }); return; }
      } catch (e) { if (/cancel|abort/i.test((e && (e.message || e.name)) || '')) return; }
      try { await navigator.clipboard.writeText(metin + ' ' + url); cfg.tost && cfg.tost('Bağlantı kopyalandı, istediğin yere yapıştır.'); }
      catch (e) { cfg.tost && cfg.tost(url); }
    }

    /* ---- bize yaz: hazır e-posta, gönderen kendisi gönderir ---- */
    function bizeYaz() {
      const konu = cfg.ad + ' – Görüş ve öneri (' + cfg.surum + ', ' + platform() + ')';
      const govde = 'Merhaba, oyunla ilgili görüşüm:\n\n\n— ' + cfg.ad + ' ' + cfg.surum + ' · ' + platform() + (cfg.ilerleme ? ' · ' + cfg.ilerleme() : '');
      location.href = 'mailto:emreanduvart@gmail.com?subject=' + encodeURIComponent(konu) + '&body=' + encodeURIComponent(govde);
    }

    /* ---- verilerimi sil: ilerleme, ayarlar, rehber, puan; satın alma bayrağı (varsa cfg.koru) korunur ---- */
    async function verileriSil() {
      const koru = cfg.koru || [];
      try { Object.keys(localStorage).forEach(k => { if (k.indexOf(cfg.onek) === 0 && !koru.includes(k)) localStorage.removeItem(k); }); } catch (e) { /* */ }
      try { sessionStorage.clear(); } catch (e) { /* */ }
      /* IndexedDB: uygulamanın kendi kökeninde (yalnız telefonda) ne varsa silinir */
      if (mobil()) { try { if (indexedDB.databases) (await indexedDB.databases()).forEach(d => d.name && indexedDB.deleteDatabase(d.name)); } catch (e) { /* */ } }
    }

    return { platform, mobil, magaza, durum, goruldu, kapat, bastan, gosterilsin, puanSorulsunMu, puanSoruldu, puanTamam, puanVer, paylas, bizeYaz, verileriSil, disAc };
  };
})();
