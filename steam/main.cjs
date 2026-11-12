/* Champion Battle Manager — masaüstü (Steam) kabuğu. Oyun, mobil sürümle aynı tek dosyalık derlemedir (oyun/index.html). */
const { app, BrowserWindow, ipcMain, shell, Menu, screen, protocol, net } = require('electron');
const { pathToFileURL } = require('node:url');
const path = require('node:path'), fs = require('node:fs');
const STEAM = require('./steam.cjs');

app.setName('Champion Battle Manager');
/* oyun app://oyun/ adresinden açılır: Modern maç görünümü (Kaptan Mecit 3, WebAssembly) dosyalarını fetch ile okuyabilsin (file:// ile okunamaz) */
protocol.registerSchemesAsPrivileged([{ scheme: 'app', privileges: { standard: true, secure: true, supportFetchAPI: true, corsEnabled: true, stream: true } }]);
const pencereDosya = () => path.join(app.getPath('userData'), 'pencere.json');
const oku = () => { try { return JSON.parse(fs.readFileSync(pencereDosya(), 'utf8')); } catch { return {}; } };
let win;

function ac() {
  const k = oku(), ek = screen.getPrimaryDisplay().workAreaSize;
  win = new BrowserWindow({
    width: k.w || Math.min(1680, ek.width), height: k.h || Math.min(1000, ek.height), x: k.x, y: k.y,
    minWidth: 1280, minHeight: 720, backgroundColor: '#16302f', title: 'Champion Battle Manager', show: false,
    autoHideMenuBar: true, fullscreen: !!k.tam,
    webPreferences: { preload: path.join(__dirname, 'preload.cjs'), contextIsolation: true, sandbox: true, spellcheck: false, backgroundThrottling: false },
  });
  if (k.buyuk) win.maximize();
  Menu.setApplicationMenu(null);
  win.loadURL('app://oyun/index.html');
  win.once('ready-to-show', () => win.show());
  win.webContents.setWindowOpenHandler(({ url }) => { if (/^https?:/.test(url)) shell.openExternal(url); return { action: 'deny' }; });
  win.webContents.on('will-navigate', (e, url) => { if (!url.startsWith('app:')) { e.preventDefault(); if (/^https?:/.test(url)) shell.openExternal(url); } });
  win.webContents.on('before-input-event', (e, i) => {
    if (i.type !== 'keyDown') return;
    if (i.key === 'F11' || (i.alt && i.key === 'Enter')) { e.preventDefault(); win.setFullScreen(!win.isFullScreen()); }
    if (i.key === 'F12' && !app.isPackaged) win.webContents.toggleDevTools();
  });
  const yaz = () => { if (!win || win.isDestroyed()) return; const b = win.getNormalBounds(); try { fs.writeFileSync(pencereDosya(), JSON.stringify({ x: b.x, y: b.y, w: b.width, h: b.height, tam: win.isFullScreen(), buyuk: win.isMaximized() })); } catch {} };
  win.on('close', yaz);
}

ipcMain.handle('cbm:tamEkran', (_e, v) => { if (win) win.setFullScreen(v == null ? !win.isFullScreen() : !!v); return win?.isFullScreen(); });
ipcMain.handle('cbm:cikis', () => app.quit());
ipcMain.handle('cbm:basarim', (_e, ad) => STEAM.basarim(ad));
ipcMain.handle('cbm:steam', () => STEAM.durum());

app.whenReady().then(() => {
  const kok = path.join(__dirname, 'oyun');
  protocol.handle('app', req => {
    const yol = path.normalize(path.join(kok, decodeURIComponent(new URL(req.url).pathname)));
    if (!yol.startsWith(kok)) return new Response('yok', { status: 404 });
    return net.fetch(pathToFileURL(yol).toString());
  });
  STEAM.baslat(); ac();
});
app.on('window-all-closed', () => app.quit());
