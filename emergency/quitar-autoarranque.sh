#!/bin/sh
# Copiar como /mnt/us/emergency.sh y reiniciar. Devuelve el Kindle a su interfaz normal.
OUT=/mnt/us/resultado.txt
{
echo "=== $(date) ==="
mntroot rw
rm -f /etc/init/kor.conf
mntroot ro
echo "kor.conf: $([ -f /etc/init/kor.conf ] && echo 'SIGUE AHI' || echo 'borrado')"
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
