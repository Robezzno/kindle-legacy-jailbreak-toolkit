#!/bin/sh
# Copiar como /mnt/us/emergency.sh y reiniciar. Bloquea telemetria, anuncios y OTA.
OUT=/mnt/us/resultado.txt
{
echo "=== $(date) ==="
mntroot rw
if grep -q "bloqueo-amazon" /etc/hosts 2>/dev/null; then
    echo "ya estaba aplicado"
else
    cat >> /etc/hosts <<'HOSTS'
# --- bloqueo-amazon ---
0.0.0.0 device-metrics-us.amazon.com
0.0.0.0 device-metrics-us-2.amazon.com
0.0.0.0 unagi.amazon.com
0.0.0.0 unagi-na.amazon.com
0.0.0.0 unagi-eu.amazon.com
0.0.0.0 fls-na.amazon.com
0.0.0.0 fls-eu.amazon.com
0.0.0.0 s.amazon-adsystem.com
0.0.0.0 aax.amazon-adsystem.com
0.0.0.0 aax-us-east.amazon-adsystem.com
0.0.0.0 aax-eu.amazon-adsystem.com
0.0.0.0 updates.amazon.com
# --- fin bloqueo-amazon ---
HOSTS
    echo "aplicado"
fi
echo "dominios bloqueados: $(grep -c '^0\.0\.0\.0' /etc/hosts)"
mntroot ro
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
