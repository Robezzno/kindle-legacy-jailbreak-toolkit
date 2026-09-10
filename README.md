<div align="center">

# 📚 Kindle Legacy Jailbreak Toolkit

**Cómo usar un Kindle liberado con el hotfix clásico en firmware 5.16, donde KUAL y KPM no funcionan**

*How to use a jailbroken Kindle running the classic hotfix on firmware 5.16, where KUAL and KPM don't work*

🔓 Sin lanzador · No launcher needed &nbsp;&nbsp;|&nbsp;&nbsp; 🐚 Root en cada arranque · Root on every boot &nbsp;&nbsp;|&nbsp;&nbsp; 📖 Verificado en KT4 · Tested on KT4

</div>

---

## 🇪🇸 Español

### El problema

Si liberaste tu Kindle con **LanguageBreak**, te quedaste con el *hotfix clásico de NiLuJe* (`bridge.conf` r17398, de 2020). Ese sistema se apoyaba en **KUAL**, que a su vez dependía de que el Kindle indexara archivos `.jar` en la biblioteca.

**Amazon rompió eso en el firmware 5.16.** El indexador dejó de reconocer cualquier cosa que no sea un libro. Resultado: 🚫 KUAL no aparece nunca en la biblioteca, hagas los reinicios que hagas.

La comunidad lo resolvió con `sh_integration` y **KPM**, que registran las aplicaciones en `/var/local/appreg.db`. Pero eso vive en los hotfixes nuevos de KindleModding, y **esos no se instalan sobre un jailbreak antiguo**: el `.bin` va firmado con las claves KMC nuevas y tu llavero sólo tiene las viejas. El Kindle acepta el archivo, lo borra… y no aplica nada.

> 🔍 Cómo confirmarlo: tras el intento, `find / -name 'kpm*'` no devuelve absolutamente nada.

### 💡 Las dos soluciones

#### 1️⃣ `emergency.sh` — root en cada arranque

El puente del jailbreak comprueba al arrancar si existe `/mnt/us/emergency.sh` y, de existir, **lo ejecuta como root**. Es un mecanismo de rescate de NiLuJe que resulta ser más potente que cualquier lanzador: no depende de la biblioteca, ni del indexador, ni de nada que Amazon pueda romper.

```sh
BRIDGE_EMERGENCY="/mnt/us/emergency.sh"
if [ -f "${BRIDGE_EMERGENCY}" ] ; then
    /bin/sh "${BRIDGE_EMERGENCY}"
```

**Uso:** copia el script que quieras a la raíz del Kindle con el nombre `emergency.sh`, expulsa y reinicia. Cada script deja un informe en `/mnt/us/resultado.txt` y **se borra a sí mismo**.

#### 2️⃣ `appreg.db` — registrar apps a mano

Lo que hace `sh_integration` son cuatro líneas de SQL. Se pueden ejecutar directamente:

```sh
sqlite3 /var/local/appreg.db <<SQL
INSERT OR IGNORE INTO interfaces(interface) VALUES('application');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','lipcId','$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','command','/usr/bin/mesquite -l $APP_ID -c file://$TARGET_DIR/');
SQL

lipc-set-prop com.lab126.appmgrd start app://$APP_ID
```

Con eso la aplicación **aparece y se lanza como nativa**, sin KUAL ni KPM. Vale tanto para apps HTML (vía `mesquite`, el WebKit del aparato) como para lanzar un script cualquiera.

### 📦 Qué hay aquí

| Script | Qué hace |
|---|---|
| 🚀 `instalar-autoarranque.sh` | KOReader arranca solo al encender |
| ↩️ `quitar-autoarranque.sh` | Vuelve a la interfaz de Amazon |
| 🛡️ `bloqueo-amazon.sh` | 12 dominios de telemetría, anuncios y OTA a `0.0.0.0` |
| 📖 `registrar-koreader.sh` | Registra KOReader como app lanzable |
| 🎨 `registrar-app-html.sh` | Registra cualquier app HTML propia |
| 🔬 `diagnostico.sh` | Vuelca el estado del sistema a un fichero |
| 📚 `opds/opds.py` | Servidor OPDS para servir tu biblioteca a KOReader por WiFi |

### ⚠️ Detalles que cuestan tiempo aprender

- **El autoarranque necesita dos reinicios.** El primero ejecuta el instalador; un job `start on started lab126_gui` no puede dispararse en el mismo arranque en que se crea, porque ese evento ya pasó.
- **Espera 85 segundos tras arrancar.** El job duerme a propósito para que la interfaz esté cargada antes de taparla. Matarla en vez de taparla rompe el arranque.
- **No mates la interfaz de Amazon**, tápala. Es lo que hace todo el mundo, y por eso.
- **`wget` del aparato no habla HTTPS** (BusyBox sin TLS). Si necesitas descargar algo, sirve por HTTP desde tu red local.

### 🔒 Seguridad

Mientras exista un `emergency.sh` en la raíz, **cualquiera que enchufe el Kindle a un ordenador puede ejecutar código como root** en el siguiente arranque. Por eso todos los scripts de este repositorio **se autodestruyen** al terminar. No dejes ninguno permanente.

---

## 🇬🇧 English

### The problem

If you jailbroke your Kindle with **LanguageBreak**, you got *NiLuJe's classic hotfix* (`bridge.conf` r17398, from 2020). That stack relied on **KUAL**, which in turn relied on the Kindle indexing `.jar` files into the library.

**Amazon broke that in firmware 5.16.** The indexer no longer picks up anything that isn't a book. Result: 🚫 KUAL never shows up in your library, no matter how many times you reboot.

The community solved this with `sh_integration` and **KPM**, which register apps in `/var/local/appreg.db`. But those live in the newer KindleModding hotfixes, and **those won't install over an older jailbreak**: the `.bin` is signed with the new KMC keys and your keystore only has the old ones. The Kindle accepts the file, deletes it… and applies nothing.

> 🔍 How to confirm: after the attempt, `find / -name 'kpm*'` returns absolutely nothing.

### 💡 The two solutions

#### 1️⃣ `emergency.sh` — root on every boot

The jailbreak bridge checks at boot whether `/mnt/us/emergency.sh` exists and, if so, **runs it as root**. It's a rescue mechanism by NiLuJe that turns out to be more powerful than any launcher: it doesn't depend on the library, the indexer, or anything Amazon can break.

**Usage:** copy the script you want to the root of the Kindle as `emergency.sh`, eject and reboot. Each script writes a report to `/mnt/us/resultado.txt` and **deletes itself**.

#### 2️⃣ `appreg.db` — register apps by hand

What `sh_integration` does is four lines of SQL. You can run them yourself (see the Spanish section above for the snippet). The app then **appears and launches as a native one**, with no KUAL and no KPM. Works both for HTML apps (via `mesquite`, the device's WebKit) and for launching an arbitrary script.

### 📦 What's in here

| Script | What it does |
|---|---|
| 🚀 `instalar-autoarranque.sh` | KOReader launches automatically at boot |
| ↩️ `quitar-autoarranque.sh` | Back to the Amazon UI |
| 🛡️ `bloqueo-amazon.sh` | 12 telemetry, ad and OTA domains to `0.0.0.0` |
| 📖 `registrar-koreader.sh` | Registers KOReader as a launchable app |
| 🎨 `registrar-app-html.sh` | Registers any HTML app of your own |
| 🔬 `diagnostico.sh` | Dumps system state to a file |
| 📚 `opds/opds.py` | OPDS server to feed your library to KOReader over WiFi |

### ⚠️ Gotchas worth knowing

- **Autostart needs two reboots.** The first runs the installer; a `start on started lab126_gui` job can't fire during the same boot that creates it — that event already passed.
- **Wait 85 seconds after boot.** The job sleeps on purpose so the framework is fully up before being covered. Killing it instead of covering it breaks boot.
- **Don't kill the Amazon UI**, cover it. There's a reason everyone does it that way.
- **The device's `wget` can't do HTTPS** (BusyBox without TLS). Serve over plain HTTP from your LAN if you need to download something.

### 🔒 Security

While an `emergency.sh` exists at the root, **anyone who plugs the Kindle into a computer can run code as root** on the next boot. That's why every script here **self-destructs** when done. Don't leave one permanently.

---

## 🙏 Créditos · Credits

Este repositorio **no reimplementa nada**: documenta cómo combinar trabajo ajeno excelente cuando la documentación oficial ya no encaja con tu aparato.

*This repo **reimplements nothing**: it documents how to combine other people's excellent work when the official docs no longer match your device.*

| Proyecto · Project | Autor · Author | Qué aporta · What it provides |
|---|---|---|
| [Hotfix / Bridge](https://www.mobileread.com/forums/showthread.php?t=225030) | **NiLuJe** | El jailbreak clásico y el mecanismo `emergency.sh` — la pieza central de todo esto |
| [LanguageBreak](https://github.com/notmarek/LanguageBreak) | **notmarek**, con Bluebotlabs, GeorgeYellow y bulltricks | El exploit del selector de idioma (FW ≤ 5.16.2.1.1) |
| [KindleModding](https://github.com/KindleModding) · [kindlemodding.org](https://kindlemodding.org/) | **KindleModding Community** | Hotfix moderno, KPM, `sh_integration`, WinterBreak, SpringBreak, AdBreak |
| [KPomo](https://github.com/crizmo/KPomo) | **crizmo**, con crédito a **HackerDude** | 🌟 De donde sale el método de registro en `appreg.db` |
| [KOReader](https://github.com/koreader/koreader) | **KOReader contributors** | El lector que hace que todo esto merezca la pena |
| [FBInk](https://github.com/NiLuJe/FBInk) | **NiLuJe** | Dibujar en el framebuffer e-ink desde consola |
| [Project Gutenberg](https://www.gutenberg.org/) | — | Los libros de dominio público que sirve el servidor OPDS |

💛 Si algo de esto te resulta útil, apoya a los autores originales, que son quienes hicieron el trabajo difícil.

*💛 If any of this is useful to you, support the original authors — they did the hard part.*

---

<div align="center">

**⚖️ Descargo · Disclaimer**

Modificar tu propio aparato es legal en la mayoría de jurisdicciones, pero **anula la garantía** y puedes dejarlo inservible.
Todo lo de aquí está verificado en un Kindle 10ª gen (KT4) con firmware 5.16.2.1.1 y en ningún otro.

*Modifying your own device is legal in most jurisdictions, but it **voids your warranty** and you can brick it.
Everything here is verified on a Kindle 10th gen (KT4) running firmware 5.16.2.1.1 and nothing else.*

📄 MIT

</div>
