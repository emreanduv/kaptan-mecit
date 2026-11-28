/* Mr. Anduv! bildirim çekirdeği (Gelişim Defteri G109). Kaynak: emreanduv/kervan-yolu www/bildirim-ortak.js; değişince bütün repolara birebir kopyalanır.
   Oyunun dünyasından yerel bildirim: oyun kapanınca 1, 3 ve 6 gün sonrası için oyunun kendi haberleri telefonda planlanır.
   Sunucu yok, hesap yok, bildirim kimliği yok, hiçbir veri gönderilmez (@capacitor/local-notifications).
   Kural: izin açılışta ya da oyunun ortasında sorulmaz; başarı anında (puan sorusunun bağlandığı yer) BildirimOrtak.basari() çağrılır,
   ikinci başarıdan sonra bir kez kibarca sorulur. Ayarlar'da aç/kapa satırı kendiliğinden eklenir. "Verilerimi sil" planlananları iptal eder.
   Uygulama öne gelince bekleyen bildirimler temizlenir, arka plana gidince yeniden planlanır.
   Kullanım (oyun betiklerinden sonra):
     <script src="bildirim-ortak.js"></script>
     <script>BildirimOrtak.kur({
       urun: 'malazgirt',                       // kısa ad (kimlik ve kayıt anahtarı)
       dil: () => 'tr' | 'en',
       mesajlar: { tr: [['Başlık','Gövde',{...ek}], ...], en: [...] },   // en az 6; {ad} gibi yer tutucular yer() ile dolar
       yer: () => ({ ad: 'Sivas' }),             // isteğe bağlı: yer tutucular
       ac: ek => {},                             // isteğe bağlı: bildirime dokununca (ek = mesajın üçüncü öğesi)
       ayarSatiri: '#setShare',                  // isteğe bağlı: Ayarlar'daki bir düğme; satırı kopyalanıp altına "Bildirimler" eklenir
       silDugmesi: '#setErase',                  // isteğe bağlı: "Verilerimi sil" düğmesi (iki dokunuşta silinince planlananlar da gider)
       kayitAnahtari: /^malazgirt/,              // isteğe bağlı: bu anahtarlar localStorage'dan silinirse bildirimler de iptal
       yazi: { soruB, soruT, evet, sonra, satir, ac, kap },  // isteğe bağlı: oyunun sesiyle metinler
       renk: { zemin:'#1b1510', yazi:'#f3e6c8', vurgu:'#d9a441' }
     })</script> */
(function () {
  'use strict';
  var LN = function () { return window.Capacitor && Capacitor.Plugins && Capacitor.Plugins.LocalNotifications; };
  var VARS = {
    tr: { soruB: 'Haber gelsin mi?', soruT: 'Oyunun dünyasında bir şey olduğunda sana kısa bir haber bırakalım. İstediğin zaman Ayarlar’dan kapatabilirsin.', evet: 'Evet, haber ver', sonra: 'Şimdi değil', satir: 'Bildirimler', ac: 'Açık', kap: 'Kapalı' },
    en: { soruB: 'Get news from the game?', soruT: 'We will leave you a short note when something happens in the game world. You can turn it off any time in Settings.', evet: 'Yes, notify me', sonra: 'Not now', satir: 'Notifications', ac: 'On', kap: 'Off' }
  };
  var O = null, K = '', durum = {};
  var GUN = [[1, 18, 30], [3, 12, 15], [6, 19, 0]];
  function oku() { try { durum = JSON.parse(localStorage.getItem(K) || '{}') || {}; } catch (e) { durum = {}; } }
  function yaz() { try { localStorage.setItem(K, JSON.stringify(durum)); } catch (e) {} }
  function dil() { try { return O.dil() === 'en' ? 'en' : 'tr'; } catch (e) { return 'tr'; } }
  function T(k) { var y = (O.yazi && O.yazi[dil()]) || {}; return y[k] || VARS[dil()][k]; }
  function kimlik(i) { var h = 0; for (var c = 0; c < O.urun.length; c++) h = (h * 31 + O.urun.charCodeAt(c)) | 0; return 19230000 + (Math.abs(h) % 9000) * 10 + i; }
  var IDS = function () { return [kimlik(0), kimlik(1), kimlik(2)]; };
  function doldur(s, y) { return String(s).replace(/\{(\w+)\}/g, function (m, a) { return y && y[a] != null ? y[a] : m; }); }
  async function izinVar() { var p = LN(); if (!p) return false; try { var r = await p.checkPermissions(); return r.display === 'granted'; } catch (e) { return false; } }
  async function iptal() { var p = LN(); if (!p) return; try { await p.cancel({ notifications: IDS().map(function (id) { return { id: id }; }) }); } catch (e) {} }
  async function planla() {
    var p = LN(); if (!p) return; await iptal();
    if (durum.acik !== 1 || !(await izinVar())) return;
    var liste = (O.mesajlar && O.mesajlar[dil()]) || []; if (!liste.length) return;
    var y = {}; try { y = O.yer ? O.yer() || {} : {}; } catch (e) {}
    var gun0 = Math.floor(Date.now() / 864e5), n = [];
    GUN.forEach(function (g, k) {
      var m = liste[(gun0 + k * 3) % liste.length], d = new Date();
      d.setDate(d.getDate() + g[0]); d.setHours(g[1], g[2], 0, 0);
      n.push({ id: IDS()[k], title: doldur(m[0], y), body: doldur(m[1], y), schedule: { at: d, allowWhileIdle: true }, extra: Object.assign({ urun: O.urun }, m[2] || {}) });
    });
    try { await p.schedule({ notifications: n }); } catch (e) { console.log('bildirim', e); }
  }
  async function izinIste() { var p = LN(); if (!p) return; try { var r = await p.requestPermissions(); durum.acik = r.display === 'granted' ? 1 : 0; } catch (e) { durum.acik = 0; } yaz(); satirYenile(); }
  function sor() {
    if (document.getElementById('bilOrtak')) return;
    var r = O.renk || {}, z = r.zemin || '#1b1712', yz = r.yazi || '#f3ead6', v = r.vurgu || '#d9a441';
    var d = document.createElement('div'); d.id = 'bilOrtak';
    d.style.cssText = 'position:fixed;inset:0;z-index:2147483000;display:flex;align-items:center;justify-content:center;background:rgba(0,0,0,.55);font-family:inherit';
    d.innerHTML = '<div style="max-width:340px;margin:16px;background:' + z + ';color:' + yz + ';border:1px solid ' + v + ';border-radius:14px;padding:18px 18px 14px;box-shadow:0 10px 40px rgba(0,0,0,.5)">' +
      '<div style="font-weight:700;font-size:17px;margin-bottom:8px">' + T('soruB') + '</div>' +
      '<div style="font-size:14px;line-height:1.45;opacity:.92;margin-bottom:14px">' + T('soruT') + '</div>' +
      '<div style="display:flex;gap:10px;justify-content:flex-end"><button id="bilOrtakH" style="font:inherit;font-size:14px;padding:9px 14px;border-radius:9px;border:1px solid ' + v + ';background:transparent;color:' + yz + '">' + T('sonra') + '</button>' +
      '<button id="bilOrtakE" style="font:inherit;font-size:14px;font-weight:700;padding:9px 14px;border-radius:9px;border:0;background:' + v + ';color:' + z + '">' + T('evet') + '</button></div></div>';
    document.body.appendChild(d);
    d.querySelector('#bilOrtakH').onclick = function () { d.remove(); };
    d.querySelector('#bilOrtakE').onclick = function () { d.remove(); izinIste(); };
  }
  // Başarı anı: ikinci başarıdan sonra bir kez sorulur; başka bir pencere (puan sorusu) açıksa bir sonrakine kalır
  function basari() {
    if (!O || !LN()) return; oku();
    durum.b = (durum.b || 0) + 1; yaz();
    if (durum.soruldu || durum.acik === 1 || durum.b < 2) return;
    setTimeout(function () {
      var acikPencere = Array.prototype.some.call(document.querySelectorAll('#rateBox,.rateBox,#puanKutu,.puanKutu,#puanKutusu,[data-puan-kutusu]'), function (e) { return !e.hidden && e.offsetParent !== null; });
      if (acikPencere || document.hidden) return;
      durum.soruldu = 1; yaz(); sor();
    }, 2600);
  }
  // Ayarlar satırı. Düğme kendi satırındaysa (yazı + düğme) satır kopyalanır; düğme bir düğme listesindeyse düğmenin kendisi
  // "Bildirimler: Açık" olarak kopyalanır. Pencere her açılışta yeniden kurulsa da satır kendiliğinden eklenir.
  var satirlar = [];
  function yazAcKap() { return durum.acik === 1 ? T('ac') : T('kap'); }
  function satirYenile() {
    satirlar = satirlar.filter(function (x) { return x.d.isConnected; });
    satirlar.forEach(function (x) { if (x.tek) x.d.textContent = T('satir') + ': ' + yazAcKap(); else { x.d.textContent = yazAcKap(); if (x.y) x.y.textContent = T('satir'); } });
  }
  async function degistir() { oku(); if (durum.acik === 1) { durum.acik = 0; yaz(); iptal(); satirYenile(); } else { durum.soruldu = 1; await izinIste(); } }
  function temizle(el) {
    // kopyada oyunun kendi bağları kalmasın: id, data-*, on*, href
    [el].concat(Array.prototype.slice.call(el.querySelectorAll('*'))).forEach(function (e) {
      Array.prototype.slice.call(e.attributes).forEach(function (a) { if (a.name === 'id' || a.name === 'href' || a.name === 'hidden' || a.name.indexOf('data-') === 0 || a.name.indexOf('on') === 0) e.removeAttribute(a.name); });
    });
    el.hidden = false; el.style.display = '';
  }
  function satirEkle() {
    if (!O.ayarSatiri || !LN()) return;
    Array.prototype.forEach.call(document.querySelectorAll(O.ayarSatiri), function (b) {
      var satir = b.parentElement; if (!satir) return;
      var tek = satir.querySelectorAll('button,a,[role=button]').length > 1 || O.ayarTek;
      var hedef = tek ? b : satir;
      if (hedef.nextElementSibling && hedef.nextElementSibling.classList.contains('bilOrtakSatir')) return;
      var k = hedef.cloneNode(true); temizle(k); k.classList.add('bilOrtakSatir');
      var x;
      if (tek) x = { d: k, tek: 1 };
      else {
        var bd = k.querySelector('button,a,[role=button]') || k.lastElementChild, yz = null;
        Array.prototype.some.call(k.children, function (c) { if (c !== bd && !c.contains(bd)) { yz = c; return true; } return false; });
        x = yz ? { d: bd, y: yz } : { d: bd, tek: 1 };   // satırda yazı yoksa düğme "Bildirimler: Açık" olur
      }
      x.d.addEventListener('click', function (e) { e.preventDefault(); e.stopImmediatePropagation(); degistir(); }, true);
      satirlar.push(x); hedef.parentNode.insertBefore(k, hedef.nextSibling);
    });
    satirYenile();
  }
  function satirKur() {
    if (!O.ayarSatiri) return; satirEkle();
    var bek = 0; new MutationObserver(function () { if (bek) return; bek = 1; setTimeout(function () { bek = 0; satirEkle(); }, 30); }).observe(document.body, { childList: true, subtree: true });
    setInterval(satirYenile, 1500);   // dil değişince yazıyı tazele
  }
  function hepsiniSil() { durum = {}; try { localStorage.removeItem(K); } catch (e) {} iptal(); satirYenile(); }
  function silmeKur() {
    // oyunun kaydı silinirse (Verilerimi sil) planlananlar da gider
    var rem = Storage.prototype.removeItem, clr = Storage.prototype.clear;
    Storage.prototype.removeItem = function (k) { rem.call(this, k); if (this === localStorage && O.kayitAnahtari && O.kayitAnahtari.test && O.kayitAnahtari.test(k) && k !== K) { durum = {}; rem.call(this, K); iptal(); satirYenile(); } };
    Storage.prototype.clear = function () { clr.call(this); if (this === localStorage) { durum = {}; iptal(); satirYenile(); } };
    if (O.silDugmesi) {
      var say = 0, zm = 0;
      document.addEventListener('click', function (e) { var t = e.target && e.target.closest && e.target.closest(O.silDugmesi); if (!t) return; say++; clearTimeout(zm); zm = setTimeout(function () { say = 0; }, 4000); if (say >= 2) { say = 0; hepsiniSil(); } }, true);
    }
  }
  function kur(o) {
    O = o; K = '_bildirim-' + o.urun; oku();
    if (!LN()) { window.BildirimOrtak.hazir = false; return; }
    satirKur(); silmeKur();
    document.addEventListener('visibilitychange', function () { if (document.hidden) planla(); else iptal(); });
    window.addEventListener('pagehide', planla);
    try {
      LN().addListener('localNotificationActionPerformed', function (a) {
        var x = a && a.notification && a.notification.extra;
        if (x && x.urun === O.urun && O.ac) setTimeout(function () { try { O.ac(x); } catch (e) { console.log(e); } }, 500);
      });
    } catch (e) {}
    iptal();
    window.BildirimOrtak.hazir = true;
  }
  window.BildirimOrtak = { kur: kur, degistir: degistir, acikMi: function () { oku(); return durum.acik === 1; }, var: function () { return !!LN(); }, basari: basari, planla: planla, iptal: iptal, sor: sor, sil: hepsiniSil, hazir: false };
})();
