const { webkit } = require('playwright');
(async () => {
  const b = await webkit.launch();
  const p = await b.newPage({ viewport: { width: 390, height: 844 }, deviceScaleFactor: 1, isMobile: true, hasTouch: true });
  const errs = [];
  p.on('pageerror', e => errs.push('PAGEERR ' + e.message + '\n' + (e.stack||'').split('\n').slice(0,4).join('\n')));
  p.on('console', m => { if (m.type() === 'error' || m.type()==='warning') errs.push(m.type() + ' ' + m.text()); });
  await p.addInitScript(()=>{window.Capacitor={isNativePlatform:()=>true,getPlatform:()=>'ios',Plugins:{InAppReview:{requestReview:async()=>{}},Share:{share:async()=>{}}}}; try{localStorage.clear()}catch(e){}});
  await p.goto('file://' + process.argv[2]);
  await p.waitForTimeout(3000);
  await p.screenshot({ path: process.argv[3] });
  console.log(errs.join('\n') || 'hata yok');
  await b.close();
})();
