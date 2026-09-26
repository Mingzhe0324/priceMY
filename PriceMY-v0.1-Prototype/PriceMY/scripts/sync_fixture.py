"""Run after editing apps/mobile/assets/catalogue.json. Regenerates companion."""
import json
from pathlib import Path
root = Path(__file__).resolve().parents[1]
source = root / 'apps/mobile/assets/catalogue.json'
data = json.loads(source.read_text())
(root / 'backend/app/catalogue.json').write_text(source.read_text())
(root / 'preview/data.js').write_text('window.CATALOGUE = ' + json.dumps(data) + ';')
preview = root / 'preview/index.html'
html = preview.read_text()
start = html.index('<style>') + len('<style>')
end = html.index('</style>', start)
html = html[:start] + (root / 'preview/style.css').read_text() + html[end:]
start = html.index('<script>') + len('<script>')
end = html.index('</script>', start)
html = html[:start] + (root / 'preview/data.js').read_text() + html[end:]
start = html.index('<script>', html.index('</script>') + 9) + len('<script>')
end = html.index('</script>', start)
html = html[:start] + (root / 'preview/app.js').read_text() + html[end:]
preview.write_text(html)
print('Synced mobile fixture → API and offline preview')
