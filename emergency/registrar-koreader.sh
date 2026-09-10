#!/bin/sh
# Registra KOReader como aplicacion nativa en appreg.db, para poder lanzarlo
# desde la interfaz sin reiniciar y sin ningun launcher (KUAL/KPM no necesarios).
#
# Registers KOReader as a native app in appreg.db, so it can be launched from
# the UI without rebooting and without any launcher (no KUAL/KPM needed).
OUT=/mnt/us/resultado.txt
APP_ID="org.koreader.launcher"
{
echo "=== $(date) ==="
[ -f /mnt/us/koreader/koreader.sh ] || { echo "ERROR: koreader.sh not found"; exit 1; }
command -v sqlite3 >/dev/null || { echo "ERROR: sqlite3 not available"; exit 1; }

sqlite3 /var/local/appreg.db <<SQL
INSERT OR IGNORE INTO interfaces(interface) VALUES('application');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','lipcId','$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','command','/bin/sh /mnt/us/koreader/koreader.sh');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','supportedOrientation','U');
SQL

echo "registered: $APP_ID"
echo "entries in appreg.db:"
sqlite3 /var/local/appreg.db "SELECT handlerId,name,value FROM properties WHERE handlerId='$APP_ID';"
echo
echo "Launch it with:  lipc-set-prop com.lab126.appmgrd start app://$APP_ID"
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
