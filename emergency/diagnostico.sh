#!/bin/sh
# Copiar como /mnt/us/emergency.sh y reiniciar. Vuelca el estado del sistema.
OUT=/mnt/us/diagnostico.txt
{
echo "=== $(date) ==="; uname -a; cat /etc/prettyversion.txt 2>/dev/null
echo; echo "--- mkk ---"; ls -la /var/local/mkk 2>/dev/null
echo; echo "--- init propios ---"; ls -la /etc/init/kor.conf 2>/dev/null
echo; echo "--- hosts ---"; grep '^0\.0\.0\.0' /etc/hosts 2>/dev/null | wc -l
echo; echo "--- red ---"; ifconfig 2>/dev/null | grep inet
echo; echo "--- logs de upstart de kor ---"; grep -i kor /var/log/messages 2>/dev/null | tail -20
} > "$OUT" 2>&1
chmod 666 "$OUT" 2>/dev/null
rm -f /mnt/us/emergency.sh
