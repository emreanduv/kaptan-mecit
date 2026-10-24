/* Oyuna yalnız gereken köprüler açılır; Node erişimi yok. */
const { contextBridge, ipcRenderer } = require('electron');
contextBridge.exposeInMainWorld('cbmMasaustu', {
  surum: process.env.npm_package_version || '4.0.0',
  platform: process.platform,
  tamEkran: v => ipcRenderer.invoke('cbm:tamEkran', v),
  cikis: () => ipcRenderer.invoke('cbm:cikis'),
  basarim: ad => ipcRenderer.invoke('cbm:basarim', ad),
  steam: () => ipcRenderer.invoke('cbm:steam'),
});
