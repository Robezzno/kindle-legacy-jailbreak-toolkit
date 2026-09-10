#!/bin/sh
# Registra una app HTML (mesquite/webkit) en appreg.db.
# Coloca tu app en /mnt/us/documents/MIAPP/ con su index.html y config.xml.
#
# Registers an HTML app (mesquite/webkit) in appreg.db.
# Put your app in /mnt/us/documents/MIAPP/ with index.html and config.xml.
#
# Basado en el metodo de KPomo (crizmo) / Based on KPomo's method (crizmo).
OUT=/mnt/us/resultado.txt

# --- EDITAR / EDIT ---
APP_NAME="miapp"
APP_ID="local.miapp"
# ---------------------

SOURCE_DIR="/mnt/us/documents/$APP_NAME"
TARGET_DIR="/var/local/mesquite/$APP_NAME"
{
echo "=== $(date) ==="
[ -d "$SOURCE_DIR" ] || { echo "ERROR: $SOURCE_DIR not found"; exit 1; }
command -v sqlite3 >/dev/null || { echo "ERROR: sqlite3 not available"; exit 1; }

rm -rf "$TARGET_DIR"
mkdir -p /var/local/mesquite
cp -r "$SOURCE_DIR" "$TARGET_DIR" && echo "copied to $TARGET_DIR"

sqlite3 /var/local/appreg.db <<SQL
INSERT OR IGNORE INTO interfaces(interface) VALUES('application');
INSERT OR IGNORE INTO handlerIds(handlerId) VALUES('$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','lipcId','$APP_ID');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','command','/usr/bin/mesquite -l $APP_ID -c file://$TARGET_DIR/');
INSERT OR REPLACE INTO properties(handlerId,name,value)
  VALUES('$APP_ID','supportedOrientation','U');
SQL

echo "registered: $APP_ID"
nohup lipc-set-prop com.lab126.appmgrd start app://$APP_ID >/dev/null 2>&1 &
echo "launch requested"
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
