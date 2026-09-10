#!/usr/bin/env python3
"""Servidor OPDS para la biblioteca de Gutenberg. Compatible con KOReader."""
import base64, html, json, os, re, urllib.parse
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

BASE = os.path.expanduser('~/biblioteca-gutenberg')
LIBROS, PORTADAS = f'{BASE}/libros', f'{BASE}/portadas'
PUERTO = int(os.environ.get('OPDS_PUERTO', 8383))
POR_PAGINA = 40
# Autenticación básica opcional: sólo se activa si se definen ambas variables.
USUARIO = os.environ.get('OPDS_USUARIO')
CLAVE = os.environ.get('OPDS_CLAVE')

def limpio(s, n=70):
    s = re.sub(r'[/\\:*?"<>|\x00-\x1f]', '', s or '').strip()
    return re.sub(r'\s+', ' ', s)[:n].strip(' .')

def cargar():
    datos = json.load(open(f'{BASE}/indice.json', encoding='utf-8'))
    salida = []
    for b in datos:
        arch = b.get('archivo') or f"{limpio(b['autor'],45)} - {limpio(b['titulo'],70)}.azw3"
        if os.path.exists(f"{LIBROS}/{arch}"):
            b['archivo'] = arch
            salida.append(b)
    return salida

e = lambda s: html.escape(str(s or ''), quote=True)

CABECERA = '''<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns="http://www.w3.org/2005/Atom" xmlns:opds="http://opds-spec.org/2010/catalog">
<id>urn:biblioteca-gutenberg</id><title>{titulo}</title><updated>2026-01-01T00:00:00Z</updated>
<author><name>Biblioteca Gutenberg</name></author>
<link rel="start" href="/" type="application/atom+xml;profile=opds-catalog;kind=navigation"/>
'''

def nav(titulo, entradas):
    x = CABECERA.format(titulo=e(titulo))
    for t, href, desc in entradas:
        x += (f'<entry><id>{e(href)}</id><title>{e(t)}</title>'
              f'<content type="text">{e(desc)}</content>'
              f'<link rel="subsection" href="{e(href)}" '
              f'type="application/atom+xml;profile=opds-catalog;kind=acquisition"/></entry>\n')
    return x + '</feed>'

def adquisicion(titulo, libros, pagina, ruta):
    x = CABECERA.format(titulo=e(titulo))
    ini = pagina * POR_PAGINA
    if ini + POR_PAGINA < len(libros):
        sep = '&' if '?' in ruta else '?'
        x += (f'<link rel="next" href="{e(ruta)}{sep}page={pagina+1}" '
              f'type="application/atom+xml;profile=opds-catalog;kind=acquisition"/>\n')
    for b in libros[ini:ini + POR_PAGINA]:
        arch = urllib.parse.quote(b['archivo'])
        jpg = urllib.parse.quote(b['archivo'].rsplit('.', 1)[0] + '.jpg')
        temas = ', '.join(b.get('temas', [])[:4])
        x += (f"<entry><id>urn:gutenberg:{b['id']}</id><title>{e(b['titulo'])}</title>\n"
              f"<author><name>{e(b['autor'])}</name></author>\n"
              f'<content type="text">{e(temas)}</content>\n'
              f'<link rel="http://opds-spec.org/image/thumbnail" href="/portada/{jpg}" type="image/jpeg"/>\n'
              f'<link rel="http://opds-spec.org/acquisition" href="/libro/{arch}" '
              f'type="application/x-mobipocket-ebook"/>\n</entry>\n')
    return x + '</feed>'

class H(BaseHTTPRequestHandler):
    def log_message(self, *a): pass

    def envia(self, cuerpo, tipo='application/atom+xml;charset=utf-8', codigo=200):
        if isinstance(cuerpo, str): cuerpo = cuerpo.encode('utf-8')
        self.send_response(codigo)
        self.send_header('Content-Type', tipo)
        self.send_header('Content-Length', str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)

    def archivo(self, carpeta, nombre, tipo):
        ruta = os.path.join(carpeta, os.path.basename(urllib.parse.unquote(nombre)))
        if not os.path.exists(ruta):
            return self.envia('no encontrado', 'text/plain', 404)
        with open(ruta, 'rb') as f:
            self.envia(f.read(), tipo)

    def autorizado(self):
        if not (USUARIO and CLAVE):
            return True
        cab = self.headers.get('Authorization', '')
        if cab.startswith('Basic '):
            try:
                u, _, c = base64.b64decode(cab[6:]).decode('utf-8').partition(':')
                if u == USUARIO and c == CLAVE:
                    return True
            except Exception:
                pass
        self.send_response(401)
        self.send_header('WWW-Authenticate', 'Basic realm="Biblioteca"')
        self.send_header('Content-Length', '0')
        self.end_headers()
        return False

    def do_GET(self):
        if not self.autorizado():
            return
        catalogo = cargar()          # relee: la descarga puede seguir en marcha
        p = urllib.parse.urlparse(self.path)
        ruta = urllib.parse.unquote(p.path)
        q = urllib.parse.parse_qs(p.query)
        pagina = int(q.get('page', ['0'])[0])

        if ruta == '/':
            autores = len({b['autor'] for b in catalogo})
            return self.envia(nav('Biblioteca Gutenberg en español', [
                ('Todos los libros', '/todos', f'{len(catalogo)} libros de dominio público'),
                ('Por autor', '/autores', f'{autores} autores'),
                ('Añadidos recientemente', '/todos?orden=id', 'Los últimos del catálogo'),
            ]))
        if ruta == '/todos':
            libros = (sorted(catalogo, key=lambda b: -b['id']) if q.get('orden')
                      else sorted(catalogo, key=lambda b: (b['autor'], b['titulo'])))
            return self.envia(adquisicion('Todos los libros', libros, pagina,
                                          '/todos?orden=id' if q.get('orden') else '/todos'))
        if ruta == '/autores':
            autores = sorted({b['autor'] for b in catalogo})
            ini = pagina * 60
            ent = [(a, '/autor?a=' + urllib.parse.quote(a), '') for a in autores[ini:ini + 60]]
            if ini + 60 < len(autores):
                ent.append((f'-- siguientes {len(autores)-ini-60} autores --',
                            f'/autores?page={pagina+1}', ''))
            return self.envia(nav('Por autor', ent))
        if ruta == '/autor':
            a = q.get('a', [''])[0]
            return self.envia(adquisicion(a, [b for b in catalogo if b['autor'] == a],
                                          pagina, '/autor?a=' + urllib.parse.quote(a)))
        if ruta == '/buscar':
            t = q.get('q', [''])[0].lower()
            libros = [b for b in catalogo
                      if t in b['titulo'].lower() or t in b['autor'].lower()]
            return self.envia(adquisicion(f'Búsqueda: {t}', libros, pagina,
                                          '/buscar?q=' + urllib.parse.quote(t)))
        if ruta.startswith('/libro/'):
            return self.archivo(LIBROS, ruta[7:], 'application/x-mobipocket-ebook')
        if ruta.startswith('/portada/'):
            return self.archivo(PORTADAS, ruta[9:], 'image/jpeg')
        self.envia('no encontrado', 'text/plain', 404)

if __name__ == '__main__':
    print(f'OPDS en http://0.0.0.0:{PUERTO}/  ({len(cargar())} libros)', flush=True)
    ThreadingHTTPServer(('0.0.0.0', PUERTO), H).serve_forever()
