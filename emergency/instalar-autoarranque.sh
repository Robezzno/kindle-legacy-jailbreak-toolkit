#!/bin/sh
# Copiar como /mnt/us/emergency.sh y reiniciar DOS veces.
# El puente del jailbreak lo ejecuta como root al arrancar.
OUT=/mnt/us/resultado.txt
{
echo "=== $(date) ==="
[ -f /mnt/us/koreader/koreader.sh ] || { echo "ERROR: falta koreader.sh"; exit 1; }
mntroot rw
cat > /etc/init/kor.conf <<'CONF'
start on started lab126_gui
stop on stopping lab126_gui

pre-start script
  test -f /mnt/us/koreader/koreader.sh || { stop; exit 1; }
  /bin/sleep 85s
end script

exec /bin/sh /mnt/us/koreader/koreader.sh --kual
CONF
mntroot ro
echo "kor.conf: $([ -f /etc/init/kor.conf ] && echo SI || echo NO)"
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
