/* Klasik denetimi: 28 lig yüklenir, tek sayılı lig / kadro / fikstür sorunu yok, dört ligde birer maç oynanır. Kullanım: node dene-lig28.js <www/klasik/index.html> */
const { chromium } = require('playwright');
(async () => {
  const b = await chromium.launch(); const p = await b.newPage({viewport:{width:390,height:844}});
  const errs=[]; p.on('pageerror', e => errs.push('PAGEERR ' + e.message));
  await p.goto('file://' + process.argv[2]); await p.waitForTimeout(1500);
  const r = await p.evaluate(() => {const o={};
    o.lig=LG_ORDER.length;o.kulup=LG_ORDER.reduce((a,k)=>a+LEAGUES[k].t.length,0);
    o.tekSayi=LG_ORDER.filter(k=>LEAGUES[k].t.length%2);
    o.kadroSorun=[];for(const k of LG_ORDER)for(const t of teams(k)){const s=squad(t),bn=bench(t);if(s.length!==11||new Set(s.map(x=>x.n)).size!==11||bn.length<5)o.kadroSorun.push(k+':'+t.id+' '+s.length+'/'+bn.length)}
    o.fikstur=[];for(const k of LG_ORDER){const fx=gercekFx(k)||fixturesFor(LEAGUES[k].t.map(r=>r[0]));const n=LEAGUES[k].t.length;const ok=fx.length===2*(n-1)&&fx.every(w=>w.length===n/2&&new Set(w.flatMap(m=>[m.h,m.a])).size===n);if(!ok)o.fikstur.push(k)}
    // her ligden bir maç simüle
    o.mac=[];for(const k of ['br','jp','mx','za']){const T=teams(k);startMatch(T[0],T[1],null,true);M.paused=false;for(let i=0;i<60*60*3;i++){step(1/60);if(M.state==='over')break}o.mac.push(k+' '+M.T[0].score+'-'+M.T[1].score+' '+M.state)}
    // kariyer
    newCareer('mx',LEAGUES.mx.t[3][0]);o.kariyer=kmKariyerGecerli(S.car)+' '+S.car.fx.length;
    return o});
  console.log(JSON.stringify(r));
  await p.evaluate(()=>{S.car=null;UI.clg='br';UI.screen='career';try{render()}catch(e){}});
  await p.waitForTimeout(300);
  console.log(errs.join('\n')||'hata yok'); await b.close();
  if(errs.length||r.lig<28||r.tekSayi.length||r.kadroSorun.length||r.fikstur.length||!String(r.kariyer).startsWith('true'))process.exit(1);
})();
