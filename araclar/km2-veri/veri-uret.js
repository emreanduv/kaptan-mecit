const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();const pg=await b.newPage();
await pg.goto('file:///home/claude/kaptan-mecit/www/index.html');await pg.waitForTimeout(1500);
const v=await pg.evaluate(()=>{const out={ligler:[]};
 for(const lg of LG_ORDER){const L=LEAGUES[lg];const lig={id:lg,ad:L.kurgu,ulke:L.ad,takimlar:[]};
  for(const r of L.t){const t=kadroKur(team(lg,r[0]),null);const sq=squad(t);const dz=Array.isArray(t.dz)&&t.dz.length===11?t.dz:null;
   lig.takimlar.push({id:t.id,ad:t.name,kisa:t.short,c1:t.c1,c2:t.c2,str:t.str,dzAd:t.dzAd||null,
    oy:sq.map((s,i)=>({no:s.no,n:s.n,st:s.st,ten:s.skin,sac:s.hair,rol:i===0?'G':dz?dz[i][2]:POS[i],yer:dz?dz[i][3]:ROLES[i],fx:dz?dz[i][0]:FORM[i][0],fy:dz?dz[i][1]:FORM[i][1],dz:!!dz}))});}
  out.ligler.push(lig)}
 out.sponsor=(typeof ADS_MUST!=='undefined'?ADS_MUST:[]);return out});
fs.writeFileSync('/home/claude/kaptan-mecit/km2/veri/takimlar.json',JSON.stringify(v));
console.log(v.ligler.map(l=>l.ad+':'+l.takimlar.length).join(', '),JSON.stringify(v.ligler[0].takimlar[0]).slice(0,600),v.sponsor);await b.close()})();
