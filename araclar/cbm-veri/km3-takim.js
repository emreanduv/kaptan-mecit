/* Kaptan Mecit 3 (Modern) takım verisi: Klasik'in verisinden (LEAGUES/HAVUZ + dizilişe göre kadro) üretilir; panolar korunur.
   Kullanım: node km3-takim.js <kaptan-mecit-klasörü> */
const {chromium}=require('playwright');const fs=require('fs');const K=process.argv[2];
(async()=>{const b=await chromium.launch();const pg=await b.newPage();
await pg.goto('file://'+K+'/www/klasik/index.html');await pg.waitForTimeout(1500);
const v=await pg.evaluate(()=>{const out={ligler:[]};
 for(const lg of LG_ORDER){const L=LEAGUES[lg];const lig={id:lg,ad:L.kurgu,ulke:L.ad,kita:L.kita||'Avrupa',it:L.it||.6,takimlar:[]};
  for(const r of L.t){const t=kadroKur(team(lg,r[0]),null);const sq=squad(t);const dz=Array.isArray(t.dz)&&t.dz.length===11?t.dz:null;
   lig.takimlar.push({id:t.id,ad:t.name,kisa:t.short,c1:t.c1,c2:t.c2,str:t.str,dzAd:t.dzAd||null,
    oy:sq.map((s,i)=>({no:s.no,n:s.n,st:s.st,ten:s.skin,sac:s.hair,rol:i===0?'G':dz?dz[i][2]:POS[i],yer:dz?dz[i][3]:ROLES[i],fx:dz?dz[i][0]:FORM[i][0],fy:dz?dz[i][1]:FORM[i][1],dz:!!dz}))});}
  out.ligler.push(lig)}
 return out});
const p=K+'/km3/veri/takimlar.json';const eski=JSON.parse(fs.readFileSync(p,'utf8'));v.panolar=eski.panolar;
fs.writeFileSync(p,JSON.stringify(v));
console.log(v.ligler.length+' lig, '+v.ligler.reduce((a,l)=>a+l.takimlar.length,0)+' kulüp, '+fs.statSync(p).size+' bayt');await b.close()})();
