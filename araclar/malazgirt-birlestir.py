#!/usr/bin/env python3
"""Malazgirt Akıncıları'nı Champion Battle Manager içine tek dosya olarak alır: www/malazgirt.html
Kullanım: python3 araclar/malazgirt-birlestir.py ../malazgirt-akincilari/www
three.min.js ve ses-kurtarici.js Champion'ın www klasöründe ortak; yazı tipleri dosyaya gömülür."""
import base64, os, re, sys
kaynak = sys.argv[1] if len(sys.argv) > 1 else '../malazgirt-akincilari/www'
hedef = os.path.join(os.path.dirname(__file__), '..', 'www', 'malazgirt.html')
h = open(os.path.join(kaynak, 'index.html'), encoding='utf-8').read()
def font(m):
    yol = os.path.join(kaynak, m.group(1))
    return 'url(data:font/woff2;base64,' + base64.b64encode(open(yol, 'rb').read()).decode() + ')'
h = re.sub(r'url\((fonts/[^)]+\.woff2)\)', font, h)
def betik(m):
    yol = m.group(1)
    if yol.endswith('three.min.js'): return '<script src="three.min.js"></script>'
    if yol == 'ses-kurtarici.js': return m.group(0)
    js = open(os.path.join(kaynak, yol), encoding='utf-8').read().replace('</script', '<\\/script')
    return '<script>\n' + js + '\n</script>'
h = re.sub(r'<script src="([^"]+)"></script>', betik, h)
assert 'js/oyun.js' not in h and 'MAC' in h, 'birleştirme eksik (maç modu kodu yok mu?)'
open(hedef, 'w', encoding='utf-8').write(h)
print('yazıldı', hedef, len(h), 'bayt')
