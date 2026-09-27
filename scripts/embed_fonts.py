"""Télécharge les polices Google du jeu dans www/fonts pour qu'il s'affiche bien hors connexion.
Si le téléchargement échoue, le jeu garde le lien en ligne (aucune erreur bloquante)."""
import re, os, urllib.request, sys
ROOT = os.path.join(os.path.dirname(__file__), '..', 'www')
idx = os.path.join(ROOT, 'index.html')
html = open(idx, encoding='utf-8').read()
m = re.search(r'<link href="(https://fonts\.googleapis\.com/css2[^"]+)" rel="stylesheet">', html)
if not m:
    print('Aucun lien de police trouvé'); sys.exit(0)
url = m.group(1).replace('&amp;', '&')
UA = 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1'
try:
    css = urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=30).read().decode()
    os.makedirs(os.path.join(ROOT, 'fonts'), exist_ok=True)
    for i, f in enumerate(sorted(set(re.findall(r'url\((https://[^)]+)\)', css)))):
        name = f'f{i}.woff2'
        data = urllib.request.urlopen(urllib.request.Request(f, headers={'User-Agent': UA}), timeout=30).read()
        open(os.path.join(ROOT, 'fonts', name), 'wb').write(data)
        css = css.replace(f, name)
    open(os.path.join(ROOT, 'fonts', 'fonts.css'), 'w', encoding='utf-8').write(css)
    html = html.replace(m.group(0), '<link href="fonts/fonts.css" rel="stylesheet">')
    html = re.sub(r'<link rel="preconnect"[^>]*>\s*', '', html)
    open(idx, 'w', encoding='utf-8').write(html)
    print('Polices intégrées')
except Exception as e:
    print('Polices non intégrées, lien en ligne conservé :', e)
