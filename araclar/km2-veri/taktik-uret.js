const {chromium}=require('playwright');const fs=require('fs');
(async()=>{const b=await chromium.launch();const pg=await b.newPage();
await pg.goto('file:///home/claude/kaptan-mecit/www/klasik/index.html');await pg.waitForTimeout(1500);
const v=await pg.evaluate(()=>({havuz:HAVUZ,dizilis:DIZILIS,sira:DIZILIS_SIRA,yaygin:YAYGIN,yakin:YAKIN_YER,grup:MV_GRUP}));
fs.writeFileSync(process.argv[2],JSON.stringify(v));
console.log(Object.keys(v.havuz).length,'kulüp',v.sira.length,'diziliş',JSON.stringify(v.havuz['tr:gs']).slice(0,200));await b.close()})();
