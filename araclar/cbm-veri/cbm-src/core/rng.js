/* Tohumlu rastgele sayı üreteci (aynı tohum → aynı dünya). */
export function hash(s) {
  let h = 2166136261;
  for (let i = 0; i < s.length; i++) { h ^= s.charCodeAt(i); h = Math.imul(h, 16777619); }
  return h >>> 0;
}
export function rng(seed) {
  let a = seed >>> 0;
  const r = () => { a = (a + 0x6D2B79F5) >>> 0; let t = a; t = Math.imul(t ^ (t >>> 15), t | 1); t ^= t + Math.imul(t ^ (t >>> 7), t | 61); return ((t ^ (t >>> 14)) >>> 0) / 4294967296; };
  r.int = (lo, hi) => lo + Math.floor(r() * (hi - lo + 1));
  r.pick = arr => arr[Math.floor(r() * arr.length)];
  r.norm = (m = 0, s = 1) => { let u = 0, v = 0; while (u === 0) u = r(); while (v === 0) v = r(); return m + s * Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v); };
  r.weighted = obj => { const e = Object.entries(obj); let t = e.reduce((s, [, w]) => s + w, 0), x = r() * t; for (const [k, w] of e) { x -= w; if (x <= 0) return k; } return e[e.length - 1][0]; };
  r.shuffle = arr => { for (let i = arr.length - 1; i > 0; i--) { const j = Math.floor(r() * (i + 1)); [arr[i], arr[j]] = [arr[j], arr[i]]; } return arr; };
  return r;
}
export const clamp = (v, a, b) => v < a ? a : v > b ? b : v;
